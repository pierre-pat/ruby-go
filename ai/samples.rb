require_relative "heuristic"

# When creating a new heuristic, remember to add it in all_heuristics.rb
# We will probably split this file in several ones later.

# TODO: 
# - the hunter (skeleton below)
# - do not fill my own territory
# - foresee a poursuit = on attack/defense (and/or use a reverse-killer?)
# - a connector
# - an eye shape constructor

# Vague idea that playing where we already have influence is moot.
# 
class Spacer < Heuristic

  def eval_move(i,j)
    enemy_inf = ally_inf = 0
    stone = @goban.stone_at?(i,j)
    
    inf = @inf.map[j][i]
    @enemy_colors.each { |c| enemy_inf += inf[c] }
    ally_inf += inf[@color]
    
    stone.neighbors.each do |s|
      inf = @inf.map[s.j][s.i]
      @enemy_colors.each { |c| enemy_inf += inf[c] }
      ally_inf += inf[@color]
    end
    total_inf = enemy_inf + ally_inf
    return 4 / (total_inf+1)
  end    
  
end

# Vague idea that playing close to border is not that great
class AvoidBorders < Heuristic

  def eval_move(i,j)
    # Distance mini from border
    dist = [distance_from_border(i), distance_from_border(j)]
    score = 0.0
    dist.each do |d|
      if d >= 3 then score += 2
      elsif d >= 2 then score += 1.5
      elsif d >= 1 then score += 1
      else score -= 2
      end
    end
    return score
  end
  
  def distance_from_border(n)
    return [n - 1, @size - n].min
  end

end

# Killers only pray on enemy groups in atari
class Killer < Heuristic

  def eval_move(i,j)
    stone = @goban.stone_at?(i,j)
    threat = support = 0
    stone.unique_enemies(@color).each do |g|
      threat += g.stones.size if g.lives == 1
    end
    $log.debug("Killer heuristic found a threat of #{threat} at #{i},#{j}") if $debug and threat>0
    return 3 * threat
  end

end

# Hunters find threats to struggling enemy groups.
# Maybe the ladder attack could fit in here.
class Hunter < Heuristic

  def eval_move(i,j)
    # TODO: hunter logic
    return 0
  end

end

# Saviors rescue ally groups in atari
class Savior < Heuristic

  def eval_move(i,j)
    stone = @goban.stone_at?(i,j)
    threat = support = 0
    stone.unique_allies(@color).each do |g|
      threat += g.stones.size if g.lives == 1
      support += g.lives - 1
    end
    return 0 if threat == 0 # no threat
    support += stone.num_lives?
    $log.debug("Savior heuristic looking at #{i},#{j}: threat is #{threat}, support is #{support}") if $debug
    return 0 if support < 2  # nothing we can do here
    return 3*(threat + support/3.0) # if 2 same size groups, we prefer the easier rescue
  end

end
