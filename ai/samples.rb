require_relative "heuristic"

# When creating a new heuristic, remember to add it in all_heuristics.rb
# We will probably split this file in several ones later.

# TODO: 
# - do not fill my own territory
# - foresee a poursuit = on attack/defense (and/or use a reverse-killer?)
# - a connector
# - an eye shape constructor

# Vague idea that playing where we already have influence is moot.
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

    corner = (@size >= 13 ? 4 : 3)
    db_x = distance_from_border(i)
    db_y = distance_from_border(j)
    dc_x = 1 + (db_x - corner).abs
    dc_y = 1 + (db_y - corner).abs
    dc = dc_x + dc_y
  
    # hacky: why play on border if no one is around?
    total_inf += (20*(2 - db_x))/(total_inf+1) if db_x<2
    total_inf += (20*(2 - db_y))/(total_inf+1) if db_y<2

    return 4.0 / (total_inf*2 + dc*2 +1)
  end    
  
  def distance_from_border(n)
    if n - 1 < @size - n then return n - 1 else return @size - n end
  end

end

# Executioner only pray on enemy groups in atari
class Executioner < Heuristic

  def eval_move(i,j)
    stone = @goban.stone_at?(i,j)
    threat = support = 0
    stone.unique_enemies(@color).each do |g|
      threat += g.stones.size if g.lives == 1
    end
    $log.debug("Executioner heuristic found a threat of #{threat} at #{i},#{j}") if $debug and threat>0
    return 3 * threat
  end

end

# Hunters find threats to struggling enemy groups.
# Ladder attack fits in here.
class Hunter < Heuristic

  # TODO: we can make simpler and cleaner.
  # The way it is now, expect a couple bugs... We will build more test cases then refactor.
  def eval_move(i,j,level=1)
    stone = @goban.stone_at?(i,j)
    threat = support = 0
    stone.unique_enemies(@color).each do |g|
      next if g.lives != 2
      next if 1 == g.all_enemies.each { |e| break(1) if e.lives < g.lives }
      $log.debug("Hunter heuristic (level #{level}) looking at #{i},#{j} threat on #{g}") if $debug
      Stone.play_at(@goban,i,j,@color)
      lives = g.all_lives
      raise "Unexpected: hunter #1" if lives.size != 1
      last_life = lives.first
      Stone.play_at(@goban,last_life.i,last_life.j,g.color) # enemy's escape move
      caught = nil
      if g.lives > 2 then caught = false
      else
        if g.lives == 0 then caught = true
        else # g.lives is 1 or 2
          last_life.neighbors.each do |ally_threatened|
            next if ally_threatened.color != @color
            caught = false if ally_threatened.group.lives < g.lives
          end
          if caught == nil
            if g.lives == 1 then caught = true
            else
              e2 = last_life.empties
              e2 = g.all_lives if e2.size != 2
              raise "Unexpected: hunter #2" if e2.size != 2
              #  recursive descent
              caught = (eval_move(e2[0].i,e2[0].j,level+1) > 0 or eval_move(e2[1].i,e2[1].j,level+1) > 0)
            end
          end
        end
      end
      Stone.undo(@goban)
      Stone.undo(@goban)
      threat += g.stones.size if caught
    end # each g
    $log.debug("Hunter heuristic found a threat of #{threat} at #{i},#{j}") if $debug and threat>0
    return 3 * threat
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
