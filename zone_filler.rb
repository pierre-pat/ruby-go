

class ZoneFiller

  # first_void_code is used only if we collect the groups during fill_with_color
  def initialize(goban,first_void_code)
    @goban = goban
    # @to_replace = EMPTY
    @first_void_code = first_void_code
    @groups = nil
  end

  # "Color" a goban zone.
  # neighbors, if given should be an array of n arrays, with n == number of colors
  # if neighbors are not given, we do simple "coloring"
  def fill_with_color(i, j, to_replace, color, neighbors=nil)
    # $log.debug("fill #{i} #{j}; replace #{to_replace} with #{color}") if $debug
    return 0 if @goban.color?(i,j) != to_replace
    size = 0
    @to_replace = to_replace
    @groups = neighbors
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

private

  # Returns true if the replacement is needed (=> i,j has a color equal to the replaced one)
  def _check(i,j)
    stone = @goban.stone_at?(i,j)
    return false if ! stone
    return true if stone.color == @to_replace
    if @groups and stone.color < @first_void_code
      @groups[stone.color].push(stone.group) if ! @groups[stone.color].find_index(stone.group)
    end
    return false
  end

end

