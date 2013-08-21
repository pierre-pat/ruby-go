require_relative "stone_constants"

def fill(goban, i, j, color)
  $log.debug("fill #{i} #{j}") if $debug
  return false if goban.color?(i,j) != EMPTY
  gaps = [[i,j,j]]
  while (gap = gaps.pop)
    $log.debug("About to do gap: #{gap} (left #{gaps.size})") if $debug
    i,j0,j1 = gap
    while goban.color?(i,j0-1) == EMPTY do j0 -= 1 end
    while goban.color?(i,j1+1) == EMPTY do j1 += 1 end
    $log.debug("Doing column #{i} from #{j0}-#{j1}") if $debug
    (i-1).step(i+1,2).each do |ix|
      curgap = nil
      j0.upto(j1) do |j|
        $log.debug("=>coloring #{i},#{j}") if $debug and ix<i
        goban.mark_a_spot!(i,j,color) if ix<i
        $log.debug("checking neighbor #{ix},#{j}") if $debug
        if goban.color?(ix,j) == EMPTY
          if ! curgap
            $log.debug("New gap in #{ix} starts at #{j}") if $debug
            curgap = j # gap start
          end
        else
          if curgap
            $log.debug("--- pushing gap [#{ix},#{curgap},#{j-1}]") if $debug
            gaps.push([ix,curgap,j-1])
            curgap = nil
          end
        end
      end # upto j
      $log.debug("--- pushing gap [#{ix},#{curgap},#{j1}]") if $debug and curgap
      gaps.push([ix,curgap,j1]) if curgap # last gap
    end # each ix
  end # while gap
  return true
end

def fill_with_color(goban,i,j,color)
 fill(goban,i,j,color)
end
