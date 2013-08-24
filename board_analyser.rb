require_relative "goban"

class EmptyZone
  attr_reader :neighbors, :code, :i, :j, :size
  
  def initialize(analyser,code,i,j,size,neighbors)
    @analyzer = analyser
    @goban = analyser.goban
    @code = code
    @i = i
    @j = j
    @size = size
    @neighbors = neighbors
  end
  
  def EmptyZone.new_neighbors(num_colors)
    return Array.new(num_colors) {[]}
  end
  
  def single_neighbor?
    one_color = nil
    @neighbors.size.times do |color|
      # is there 1 or more neighbors of this color?
      if @neighbors[color].size >= 1
        return nil if one_color # we already had neighbors in another color
        one_color = color
      end
    end
    return one_color
  end
  
  def to_s
    s = "zone #{@code} (#{@analyzer.zone_code_to_char(@code)}/#{@i},#{@j}), size #{@size}"
    neighbors.size.times do |color|
      s << ", #{@neighbors[color].size} #{@goban.color_name(color)} neighbors"
    end
    return s
  end

  def debug_dump
    puts to_s
    @neighbors.size.times do |color|
      print "    Color #{color} (#{@goban.color_to_char(color)}):"
      @neighbors[color].each do |neighbor|
        print " ##{neighbor.ndx}"
      end
    end
    print "\n"
  end
  
end

class BoardAnalyser

  attr_reader :goban, :scores

  # neighbors if given should be an array of n arrays, with n == number of colors
  def initialize(goban)
    @goban = goban
    @backup = nil
    @to_replace = EMPTY
    @first_empty_zone_code = 100 # anything above Goban::COLOR_CHARS.size is OK
    @zones = []
  end
  
  def restore
    $log.debug("Analyser: restoring goban...") if $debug
    @goban.load_image(@backup)
  end

  # Returns true if the replacement is needed (=> i,j has a color equal to the replaced one)
  def _check(i,j)
    stone = @goban.stone_at?(i,j)
    return false if ! stone
    return true if stone.color == @to_replace
    if @neighbors and stone.color < @first_empty_zone_code
      @neighbors[stone.color].push(stone.group) if ! @neighbors[stone.color].find_index(stone.group)
    end
    return false
  end

  # if neighbors are not given, we do simple "coloring"
  def fill_with_color(i, j, to_replace, color, neighbors=nil)
    # $log.debug("fill #{i} #{j} with #{color}") if $debug
    return 0 if @goban.color?(i,j) != to_replace
    size = 0
    @to_replace = to_replace
    @neighbors = neighbors
    gaps = [[i,j,j]]
    while (gap = gaps.pop)
      # $log.debug("About to do gap: #{gap} (left #{gaps.size})") if $debug
      i,j0,j1 = gap
      next if @goban.color?(i,j0) != to_replace # gap already done by another path
      while _check(i,j0-1) do j0 -= 1 end
      while _check(i,j1+1) do j1 += 1 end
      size += j1-j0+1
      # $log.debug("Doing column #{i} from #{j0}-#{j1}") if $debug
      (i-1).step(i+1,2).each do |ix|
        curgap = nil
        j0.upto(j1) do |j|
          # $log.debug("=>coloring #{i},#{j}") if $debug and ix<i
          @goban.mark_a_spot!(i,j,color) if ix<i # FIXME: we have some dupes here
          # $log.debug("checking neighbor #{ix},#{j}") if $debug
          if _check(ix,j)
            if ! curgap
              # $log.debug("New gap in #{ix} starts at #{j}") if $debug
              curgap = j # gap start
            end
          else
            if curgap
              # $log.debug("--- pushing gap [#{ix},#{curgap},#{j-1}]") if $debug
              gaps.push([ix,curgap,j-1])
              curgap = nil
            end
          end
        end # upto j
        # $log.debug("--- pushing gap [#{ix},#{curgap},#{j1}]") if $debug and curgap
        gaps.push([ix,curgap,j1]) if curgap # last gap
      end # each ix
    end # while gap
    return size
  end

  # After calling this the board is altered.
  # Call restore if the game needs to continue.
  def analyse_empty_zones
    $log.debug("Analyzing empty zones...") if $debug
    @backup = @goban.image?
    zone_code = @first_empty_zone_code
    @zones.clear
    
    1.upto(@goban.size) do |j|
      1.upto(@goban.size) do |i|
        neighbors = EmptyZone.new_neighbors(@goban.num_colors)
        if (size = fill_with_color(i,j,EMPTY,zone_code,neighbors)) > 0
          @zones.push(EmptyZone.new(self,zone_code,i,j,size,neighbors))
          zone_code += 1
        end
      end
    end
  end
  
  def count_score
    $log.debug("Counting score...") if $debug
    analyse_empty_zones
    # TODO continue this
    @scores=Array.new(@goban.num_colors,0)
    @zones.each do |zone|
      single_color = zone.single_neighbor?
      if single_color
        # we have territory; count it and fill it with proper color
        @scores[single_color] += zone.size
        fill_with_color(zone.i,zone.j,zone.code,@goban.color_to_territory_color(single_color))
      end
    end
    @scores.size.times { |i| $log.debug("Player #{i}: #{scores[i]} points") } if $debug
  end
  
  def image?
    return @goban.to_text(false,false,","){ |s| color_to_char(s.color) }.chop
  end
  
  def debug_dump  
    print @goban.to_text { |s| color_to_char(s.color) }
    @zones.each { |zone| zone.debug_dump }
  end
  
  def color_to_char(color)
      return (color >= @first_empty_zone_code ? zone_code_to_char(color) : @goban.color_to_char(color))
  end
  
  def zone_code_to_char(code)
    return ("A".ord + code - @first_empty_zone_code).chr
  end
  
end
