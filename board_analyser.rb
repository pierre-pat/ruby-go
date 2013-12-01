require "set"

require_relative "goban"
require_relative "zone_filler"

# A void in an empty zone surrounded by (and including) various groups.
# NB: when a void has a single color around; we call this an eye. Can be discussed...
class Void
  attr_reader :code, :i, :j, :size, :groups, :eye_color, :owner
  
  # code is the void code (like a color but higher index)
  # neighbors is an array of n arrays, with n == number of colors
  def initialize(analyser,code,i,j,size,neighbors)
    @analyzer = analyser
    @goban = analyser.goban
    @code = code
    @i = i
    @j = j
    @size = size
    @groups = neighbors # neighboring groups (array of arrays; 1st index is color)
    @eye_color = nil # stays nil if not an eye
    @owner = nil
  end
  
  # Call it once. Populates @eye_color
  # @eye_color stays nil if there is more than 1 color around (not an eye) or full board empty
  def eye_check!
    one_color = nil
    @groups.size.times do |c|
      # is there 1 or more groups of this color?
      if @groups[c].size >= 1
        if one_color # we already had groups in another color
          one_color = nil
          break
        end
        one_color = c
      end
    end
    @eye_color = one_color
    # Now tell the groups about this void
    if one_color
      set_owner(one_color)
      @groups.each { |n| n.each { |g| g.add_void(self,true) } }
      $log.debug("Color #{one_color} surrounds #{self} (eye)") if $debug
    else
      @groups.each { |n| n.each { |g| g.add_void(self) } }
      $log.debug("#{self} has to be sorted out...") if $debug
    end
  end
  
  def set_owner(color)
    @owner = color
  end
  
  def to_s
    s = "void #{@code} (#{@analyzer.void_code_to_char(@code)}/#{@i},#{@j}), size #{@size}"
    @groups.size.times do |color|
      s << ", #{@groups[color].size} #{@goban.color_name(color)} neighbors"
    end
    return s
  end

  def debug_dump
    puts to_s
    @groups.size.times do |color|
      print "    Color #{color} (#{@goban.color_to_char(color)}):"
      @groups[color].each do |neighbor|
        print " ##{neighbor.ndx}"
      end
    end
    print "\n"
  end
  
end



class BoardAnalyser

  attr_reader :goban, :scores, :prisoners

  def initialize(goban)
    @goban = goban
    @backup = nil
    @first_void_code = 100 # anything above Goban::COLOR_CHARS.size is OK
    @voids = []
    @all_groups = Set.new
    @num_colors = goban.num_colors
  end

  def count_score
    $log.debug("Counting score...") if $debug
    @scores = Array.new(@num_colors,0)
    @prisoners = Group.prisoners?(@goban)
    @backup = @goban.image?

    find_voids
    find_eyes
    find_stronger_owners
    find_dying_groups
    find_dame_voids
    color_voids

    @voids.each do |v|
      @scores[v.owner] += v.size if v.owner
    end
    
    debug_dump if $debug
  end
  
  def enlarge
    count_score
    backup = @backup
    restore
    
    debug_dump
    stones = []
    rows = backup.split(/\"|,/)
    size = @goban.size
    size.downto(1) do |j|
      row = rows[size-j]
      1.upto(size) do |i|
        color = @goban.char_to_color(row[i-1])
        if color != EMPTY
          stone = @goban.stone_at?(i,j)
          stone.neighbors.each do |n|
            stones.push(Stone.play_at(@goban,n.i,n.j,stone.color)) if n.color == EMPTY
          end
        end
      end
    end
    count_score
    restore
  end
  
  def restore
    return if !@backup
    $log.debug("Analyser: restoring goban...") if $debug
    @goban.load_image(@backup)
    @backup = nil
  end
  
  def color_to_char(color)
      return (color >= @first_void_code ? void_code_to_char(color) : @goban.color_to_char(color))
  end

  def image?
    return @goban.to_text(false,false,","){ |s| color_to_char(s.color) }.chop
  end
  
  def void_code_to_char(code)
    return ("A".ord + code - @first_void_code).chr
  end
  
  def debug_dump  
    print @goban.to_text { |s| color_to_char(s.color) }
    @voids.each { |v| v.debug_dump }

    print "\nGroups with 2 eyes or more: "
    @all_groups.each { |g| print "#{g.ndx}," if g.eyes.size >= 2 }
    print "\nGroups with 1 eye: "
    @all_groups.each { |g| print "#{g.ndx}," if g.eyes.size == 1 }
    print "\nGroups with no eye: "
    @all_groups.each { |g| print "#{g.ndx}," if g.eyes.size == 0 }
    print "\nScore:\n"
    @scores.size.times { |i| puts "Player #{i}: #{scores[i]} points" }
  end

private

  # After calling this the board is altered.
  # Call restore if the game needs to continue.
  def find_voids
    $log.debug("Find voids...") if $debug
    void_code = @first_void_code
    @all_groups.each { |g| g.reset_voids }
    @all_groups.clear
    @voids.clear
    @filler = ZoneFiller.new(goban,@first_void_code)
    
    1.upto(@goban.size) do |j|
      1.upto(@goban.size) do |i|
        neighbors = Array.new(@num_colors) {[]}
        if (size = @filler.fill_with_color(i,j,EMPTY,void_code,neighbors)) > 0
          @voids.push(Void.new(self,void_code,i,j,size,neighbors))
          void_code += 1
          # keep all the groups
          neighbors.each { |n| n.each { |g| @all_groups.add(g) } }
        end
      end
    end
  end

  # Find voids surrounded by a single color -> eyes
  def find_eyes
    @voids.each { |v| v.eye_check! }
  end
  
  # Decides who owns a void by comparing the "liveness" of each side
  def find_stronger_owners
    @voids.each do |v|
      next if v.eye_color
      lives = Array.new(@num_colors,0)
      @num_colors.times do |c|
        v.groups[c].each do |g|
          lives[c] += g.lives
        end
      end
      more_lives = lives.max
      if lives.count { |l| l == more_lives } == 1 # make sure we have a winner, not a tie
        c = lives.find_index(more_lives)
        v.set_owner(c)
        $log.debug("Deciding that color #{c}, with #{more_lives} lives, owns #{v}") if $debug
      end
    end
  end
  
  # Reviews the groups and declare "dead" the ones who do not own any void
  def find_dying_groups
    @all_groups.each do |g|
      next if g.eyes.size != 0
      next if g.voids.any? {|v| v.owner == g.color}
      # find the owner of one void around (simplistic...)
      owner = nil
      g.voids.each do |v|
        if v.owner
          owner = v.owner
          break
        end
      end
      # if anyway no one knows who owns the voids around g, leave it
      next if ! owner
      stone = g.stones.first
      taken = @filler.fill_with_color(stone.i,stone.j,g.color,@goban.color_to_dead_color(g.color))
      @prisoners[g.color] += taken
      @scores[owner] += taken
      $log.debug("Hence #{g} is considered dead (#{taken} prisoners; 1st stone #{stone})") if $debug
    end
  end

  # Looks for "dame" = neutral voids (if alive groups from more than one color are around)
  def find_dame_voids
    @voids.each do |v|
      next if v.eye_color
      alive_colors = []
      @num_colors.times do |c|
        v.groups[c].each do |g|
          if group_liveliness?(g) >= 1 then alive_colors.push(c); break end
        end
      end
      v.set_owner(nil) if alive_colors.size >= 2
    end
  end
  
  # Colors the voids with owner's color
  def color_voids
    @voids.each do |v|
      c = (v.owner ? @goban.color_to_territory_color(v.owner) : Goban::UNKNOWN_ZONE)
      @filler.fill_with_color(v.i, v.j, v.code, c)
    end
  end
  
  # Returns a number telling how "alive" a group is. TODO: review this
  # Really basic logic for now.
  # - eyes count a lot (proportionaly to their size; instead we should determine if an
  #   eye shape is right to make 2 eyes)
  # - owned voids count much less (1 point per void, no matter its size)
  # - non-owned voids (undetermined owner or enemy-owned void) count for 0
  # NB: for end-game counting, this logic is enough because undetermined situations
  # have usually all been resolved (or this means both players cannot see it...)
  def group_liveliness?(g)
    g.eyes.size + g.voids.count {|z| z.owner == g.color}
  end

end
