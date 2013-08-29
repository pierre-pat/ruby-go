require_relative "player"
require_relative "goban"
require_relative "influence_map"
require_relative "ai/all_heuristics"
require_relative "test/time_keeper"


class Ai1Player < Player
  
  attr_reader :goban, :inf, :enemy_colors
  
  def initialize(controller, color)
    super(false, controller, color)
    @inf = InfluenceMap.new(@goban)
    @size = @goban.size
    
    # trying to minimize the burden of multiplayer logic over 2 player logic
    @enemy_colors = []
    @goban.num_colors.times { |c| @enemy_colors.push(c) if c != color }

    @heuristics = []
    Heuristic.all_heuristics.each do |cl|
      @heuristics.push(cl.new(self))
    end

    @timer = TimeKeeper.new
    @timer.calibrate(0.7)
  end

  def get_move
    @timer.start("AI move",0.05,3)

    prepare_eval

    best_score = 0.0
    best_i = best_j = -1
    1.upto(@size) do |j|
      1.upto(@size) do |i|
        score = eval_move(i,j)
        # Keep the best move
        if score > best_score
          second_best = best_score
          $log.debug("#{Goban.move_as_string(i,j)} becomes the best move with #{score} (2nd best was #{Goban.move_as_string(best_i,best_j)} with #{best_score})") if $debug
          best_score = score
          best_i = i
          best_j = j
        end
      end
    end

    @timer.stop
    
    return "pass" if best_score == 0.0
    return Goban.move_as_string(best_i, best_j)
  end

  def prepare_eval
    @inf.build_map!
  end

  def eval_move(i,j)
    return 0.0 if ! Stone.valid_move?(@goban, i, j, @color)
    score = 0.0
    @heuristics.each do |h|
      score += h.eval_move(i,j)
    end
    return score
  end

end
