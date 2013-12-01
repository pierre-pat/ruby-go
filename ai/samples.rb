require_relative "heuristic"

# When creating a new heuristic, remember to add it in all_heuristics.rb
# We will probably split this file in several ones later.

# TODO: 
# - do not fill my own territory (potential territory recognition will use analyser.enlarge method)
# - identify all foolish moves (like NoEasyPrisoner but once for all) in a map that all heuristics can use
# - foresee a poursuit = on attack/defense (and/or use a reverse-killer?)
# - an eye shape constructor

# Vague idea that playing where we already have influence is moot.
class Spacer < Heuristic

  def initialize(player)
    super
    @main_coeff = get_gene("main_coeff", 4.0, 0.0, 8.0)
    @infl_coeff = get_gene("infl_coeff", 2.0, 0.0, 8.0)
    @corner_coeff = get_gene("corner_coeff", 2.0, 0.0, 8.0)
  end

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

    corner = 3
    db_x = distance_from_border(i)
    db_y = distance_from_border(j)
    dc_x = 1 + (db_x - corner).abs
    dc_y = 1 + (db_y - corner).abs
    dc = dc_x + dc_y
  
    # hacky: why play on border if no one is around?
    total_inf += (20*(2 - db_x))/(total_inf+1) if db_x<2
    total_inf += (20*(2 - db_y))/(total_inf+1) if db_y<2

    return @main_coeff / (total_inf * @infl_coeff + dc * @corner_coeff +1)
  end    
  
  def distance_from_border(n)
    if n - 1 < @size - n then return n - 1 else return @size - n end
  end

end

class Pusher < Heuristic

  def initialize(player)
    super
    @ally_coeff = get_gene("ally_coeff", 0.1, 0.01, 4.0)
    @enemy_coeff = get_gene("enemy_coeff", 0.4, 0.01, 4.0)
  end

  def eval_move(i,j)
    stone = @goban.stone_at?(i,j)
    inf = @inf.map[j][i]
    enemy_inf = 0
    @enemy_colors.each { |c| enemy_inf += inf[c] }
    ally_inf = inf[@color]
    
    return 0 if enemy_inf == 0 or ally_inf == 0
    $log.debug("Pusher heuristic sees influences #{ally_inf} - #{enemy_inf} at #{i},#{j}") if $debug
    return @enemy_coeff * enemy_inf - @ally_coeff * ally_inf
  end

end

# Executioner only preys on enemy groups in atari
class Executioner < Heuristic

  def initialize(player)
    super
    @main_coeff = get_gene("main_coeff", 3.0, 1.0, 10.0)
  end

  def eval_move(i,j)
    stone = @goban.stone_at?(i,j)
    threat = 0
    stone.unique_enemies(@color).each do |g|
      threat += g.stones.size if g.lives == 1
    end
    $log.debug("Executioner heuristic found a threat of #{threat} at #{i},#{j}") if $debug and threat>0
    return @main_coeff * threat
  end

end

# Hunters find threats to struggling enemy groups.
# Ladder attack fits in here.
class Hunter < Heuristic

  def initialize(player,consultant=false)
    super
    @main_coeff = get_gene("main_coeff", 3.0, 1.0, 10.0)
  end

  def eval_move(i,j,level=1)
    stone = @goban.stone_at?(i,j)
    threat = 0
    stone.unique_enemies(@color).each do |g|
      next if g.lives != 2
      next if 1 == g.all_enemies.each { |e| break(1) if e.lives < g.lives }
      $log.debug("Hunter heuristic (level #{level}) looking at #{i},#{j} threat on #{g}") if $debug
      Stone.play_at(@goban,i,j,@color) # our attack takes one of the 2 last lives (the one in i,j)
      caught = atari_is_caught?(g,level)
      Stone.undo(@goban)
      threat += g.stones.size if caught
    end # each g
    $log.debug("Hunter heuristic found a threat of #{threat} at #{i},#{j}") if $debug and threat>0
    return @main_coeff * threat
  end

  def atari_is_caught?(g,level=1)
    all_lives = g.all_lives
    raise "Unexpected: hunter #1: #{all_lives.size}" if all_lives.size != 1
    last_life = all_lives.first
    stone = Stone.play_at(@goban,last_life.i,last_life.j,g.color) # enemy's escape move
    begin
      return escaping_atari_is_caught?(stone,level)
    ensure
      Stone.undo(@goban)
    end
  end

  # stone is the atari escape move
  def escaping_atari_is_caught?(stone,level=1)
    g = stone.group
    return false if g.lives > 2
    return true if g.lives == 0
    # g.lives is 1 or 2
    stone.neighbors.each do |ally_threatened|
      next if ally_threatened.color != @color
      return false if ally_threatened.group.lives < g.lives
    end
    return true if g.lives == 1
    empties = stone.empties
    empties = g.all_lives if empties.size != 2
    raise "Unexpected: hunter #2" if empties.size != 2
    e1 = empties[0]; e2 = empties[1] # need to keep the empties ref since all_lives returns volatile content
    #  recursive descent
    $log.debug("Enemy has 2 lives left: #{e1} and #{e2}") if $debug
    return (eval_move(e1.i,e1.j,level+1) > 0 or eval_move(e2.i,e2.j,level+1) > 0)
  end
  
end

# Saviors rescue ally groups in atari
class Savior < Heuristic

  def initialize(player)
    super
    @enemy_hunter = Hunter.new(player,true)
    @main_coeff = get_gene("main_coeff", 3.0, 1.0, 10.0)
  end
  
  def init_color
    super
    @enemy_hunter.init_color
  end

  def eval_move(i,j)
    stone = @goban.stone_at?(i,j)
    threat = support = 0
    group = nil
    stone.unique_allies(@color).each do |g|
      if g.lives == 1
        threat += g.stones.size
        group = g # usually only 1 is found but it works for more
      else
        support += g.lives - 1
      end
    end
    return 0 if threat == 0 # no threat
    support += stone.num_lives?
    $log.debug("Savior heuristic looking at #{i},#{j}: threat is #{threat}, support is #{support}") if $debug
    return 0 if support < 2  # nothing we can do here
    if support == 2
      # when we get 2 lives from the new stone, get our "consultant hunter" to evaluate if we can escape
      return 0 if @enemy_hunter.atari_is_caught?(group)
    end
    $log.debug("=> Savior heuristic thinks we can save a threat of #{threat} in #{i},#{j}") if $debug
    return @main_coeff * threat
  end

end

# Basic: a move that connects 2 of our groups is good.
# TODO: this could threaten our potential for keeping eyes, review this.
class Connector < Heuristic

  def initialize(player)
    super
    @infl_coeff = get_gene("infl_coeff", 1.0, 0.01, 3.0)
    @ally_coeff1 = get_gene("ally_coeff1", 3.0, 0.01, 3.0)
    @ally_coeff2 = get_gene("ally_coeff2", 5.0, 0.01, 8.0)
  end

  def eval_move(i,j)
    # we care a lot if the enemy is able to cut us,
    # and even more if by connecting we cut them...
    # TODO: the opposite heuristic - a cutter; and make both more clever.
    stone = @goban.stone_at?(i,j)
    enemies = stone.unique_enemies(@color)
    num_enemies = enemies.size
    allies = stone.unique_allies(@color)
    num_allies = allies.size
    return 0 if num_allies < 2 # nothing to connect here
    return 0 if num_allies == 3 and num_enemies == 0 # in this case we never want to connect unless enemy comes by
    return 0 if num_allies == 4
    if num_allies == 2
      s1 = s2 = nil; non_unique_count = 0
      stone.neighbors.each do |s|
        s1 = s if s.group == allies[0]
        s2 = s if s.group == allies[1]
        non_unique_count += 1 if s.color == @color
      end
      return 0 if non_unique_count == 3 and num_enemies == 0
      # Case of diagonal (strong) stones (TODO: handle the case with a 3rd stone in same group than 1 or 2)
      if non_unique_count == 2 and s1.i != s2.i and s1.j != s2.j
        # No need to connect if both connection points are free
        return 0 if @goban.empty?(s1.i,s2.j) and @goban.empty?(s2.i,s1.j)
      end
    end
    $log.debug("=> Connector heuristic thinks we should connect in #{i},#{j} (allies:#{num_allies} enemies: #{num_enemies})") if $debug
    return @infl_coeff / @inf.map[j][i][@color] if num_enemies == 0
    return @ally_coeff1 * num_allies if num_enemies == 1
    return @ally_coeff2 * num_allies
  end

end

class NoEasyPrisoner < Heuristic

  def initialize(player)
    super
    set_as_negative
    @main_coeff = get_gene("main_coeff", 3.0, 0.01, 10.0)
    @enemy_hunter = Hunter.new(player,true)
  end

  def init_color
    super
    @enemy_hunter.init_color
  end

  def eval_move(i,j)
    # NB: snapback is handled in hunter; here we just notice the sacrifice of a stone, which will
    # be balanced by the profit measured by hunter (e.g. lose 1 but kill 3).
    begin
      stone = Stone.play_at(@goban,i,j,@color)
      g = stone.group
      score = - @main_coeff * g.stones.size
      if g.lives == 1
        $log.debug("NoEasyPrisoner heuristic says #{i},#{j} is plain foolish (#{score})") if $debug
        return score
      end
      if g.lives == 2
        if @enemy_hunter.escaping_atari_is_caught?(stone)
          $log.debug("NoEasyPrisoner heuristic (backed by Hunter) says #{i},#{j} is foolish  (#{score})") if $debug
          return score
        end
      end
      return 0 # "all seems fine with this move"
    ensure
      Stone.undo(@goban)
    end
  end

end
