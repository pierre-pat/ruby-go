require_relative "goban"

class EmptyZone
  attr_reader :neighbors
  
  def initialize(i,j,size,neighbors)
    @i = i
    @j = j
    @size = size
    @neighbors = neighbors
  end
  
  def EmptyZone.new_neighbors
    return [[],[]]
  end
  
  def to_s # TODO with a loop
    return "zone #{@i}#{@j}, size #{@size}, " +
      "#{@neighbors[0].size} black neighbors, " + 
      "#{@neighbors[1].size} white neighbors"
  end

end

class BoardAnalyser

  # neighbors if given should be an array of n arrays, with n == number of colors
  def initialize(goban, to_replace = EMPTY)
    @goban = goban
    @to_replace = to_replace
    @first_empty_zone_code = 10 # anything above 5 is OK
    @zones = []
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

  def fill_with_color(i, j, color)
    $log.debug("fill #{i} #{j} with #{color}") if $debug
    return 0 if @goban.color?(i,j) != @to_replace
    size = 0
    @neighbors = EmptyZone.new_neighbors
    gaps = [[i,j,j]]
    while (gap = gaps.pop)
      $log.debug("About to do gap: #{gap} (left #{gaps.size})") if $debug
      i,j0,j1 = gap
      while _check(i,j0-1) do j0 -= 1 end
      while _check(i,j1+1) do j1 += 1 end
      size += j1-j0+1
      $log.debug("Doing column #{i} from #{j0}-#{j1}") if $debug
      (i-1).step(i+1,2).each do |ix|
        curgap = nil
        j0.upto(j1) do |j|
          # $log.debug("=>coloring #{i},#{j}") if $debug and ix<i
          @goban.mark_a_spot!(i,j,color) if ix<i
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

  def analyse_empty_zones
    zone_code = @first_empty_zone_code
    1.upto(@goban.size) do |j|
      1.upto(@goban.size) do |i|
        if (size = fill_with_color(i,j,zone_code)) > 0
          @zones.push(EmptyZone.new(i,j,size,@neighbors))
          zone_code += 1
        end
      end
    end
    debug_dump if $debug
  end
    
  def debug_dump  
    print @goban._to_console { |s|
      if s.color >= @first_empty_zone_code
        ("A".ord + s.color - @first_empty_zone_code).chr
      else
        @goban.stone_to_text(s.color)
      end
    }
    @zones.each do |zone|
      puts "\nZone: #{zone}"
      0.upto(1) do |color|
        print "    Color #{color}:"
        zone.neighbors[color].each do |neighbor|
          print " ##{neighbor.ndx}"
        end
      end
    end
  end
  
end
