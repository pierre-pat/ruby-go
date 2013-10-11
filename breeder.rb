require 'trollop'

require_relative "logging"
require_relative "time_keeper"
require_relative "controller"
require_relative "ai1_player"

$debug_breed = false # TODO move me somewhere else?

class Breeder

  GENERATION_SIZE = 30
  NUM_TOURNAMENTS = 1
  NUM_MATCH_PER_AI_PER_TOURNAMENT = 3
  MUTATION_RATE = 0.05 # e.g. 0.02 is 2%
  WIDE_MUTATION_RATE = 0.20 # how often do we "widely" mutate
  KOMI = 1.5
  TOO_SMALL_SCORE_DIFF = 3 # if final score is less that this, see it as a tie game

  def initialize(game_size)
    @size = game_size
    @timer = TimeKeeper.new
    @timer.calibrate(0.7)
    @controller = Controller.new
    @controller.new_game(@size)
    @player1 = Ai1Player.new(@controller, BLACK)
    @player2 = Ai1Player.new(@controller, WHITE)
    @controller.set_player(@player1)
    @controller.set_player(@player2)
    @controller.set_log_level("all=0")
    @gen_size = GENERATION_SIZE
    first_generation
  end

  def first_generation
    @control_genes = @player1.genes.clone
    @generation = []
    @new_generation = []
    @gen_size.times do |i|
      @generation.push(@player1.genes.clone.mutate_all!)
      @new_generation.push(Genes.new)
    end
    @score_diff = []
  end
  
  # Plays a game and returns the score difference in points
  def play_game(name1,name2,p1,p2)
    # @timer.start("AI VS AI game",0.5,3)
    @controller.new_game(@size,2,0,KOMI)
    @player1.prepare_game(p1)
    @player2.prepare_game(p2)
    score_diff = @controller.play_breeding_game
    # @timer.stop(false) # no exception if it takes longer but an error in the log
    $log.debug("\n##{name1}:#{p1}\nagainst\n##{name2}:#{p2}") if $debug_breed
    $log.debug("Distance: #{'%.02f' % p1.distance(p2)}") if $debug_breed
    $log.debug("Score: #{score_diff}") if $debug_breed
    $log.debug("Moves: #{@controller.history_str}") if $debug_breed
    @controller.goban.console_display if $debug_breed
    return score_diff
  end

  def run
    NUM_TOURNAMENTS.times do |i| # TODO: Find a way to appreciate the progress
      @timer.start("Breeding tournament #{i+1}/#{NUM_TOURNAMENTS}: each of #{@gen_size} AIs plays #{NUM_MATCH_PER_AI_PER_TOURNAMENT} games",5.5,36)
      one_tournament
      @timer.stop(false)
      reproduction
      control
    end
    control_issue
  end
  
  def one_tournament
    $log.debug("One tournament starts for #{@generation.size} AIs") if $debug_breed
    @gen_size.times { |p1| @score_diff[p1] = 0 }
    NUM_MATCH_PER_AI_PER_TOURNAMENT.times do
      @gen_size.times do |p1|
        p2 = rand(@gen_size - 1)
        p2 = @gen_size - 1 if p2 == p1
        diff = play_game(p1.to_s,p2.to_s,@generation[p1],@generation[p2])
        if diff.abs < TOO_SMALL_SCORE_DIFF
          diff = 0
        else
          diff = diff.abs / diff # get sign of diff only -> -1,+1
        end
        # diff is now -1, 0 or +1
        @score_diff[p1] += diff
        $log.debug("Match ##{p1} against ##{p2}; final scores ##{p1}:#{@score_diff[p1]}, ##{p2}:#{@score_diff[p2]}") if $debug_breed
      end
    end
    
    @rank
  end
  
  def reproduction
    $log.debug("=== Reproduction time for #{@generation.size} AI") if $debug_breed
    @picked = Array.new(@gen_size,0)
    @max_score = @score_diff.max
    @winner = @generation[@score_diff.find_index(@max_score)]
    @pick_index = 0
    0.step(@gen_size-1,2) do |i|
      parent1 = pick_parent
      parent2 = pick_parent
      parent1.mate(parent2, @new_generation[i], @new_generation[i+1], MUTATION_RATE, WIDE_MUTATION_RATE)
    end
    @gen_size.times { |i| $log.debug("##{i}, score #{@score_diff[i]}, picked #{@picked[i]} times") } if $debug_breed
    # swap new generation to replace old one
    swap = @generation
    @generation = @new_generation
    @new_generation = swap
    @generation[0] = @winner # TODO review this; we force the winner (a parent) to stay alive
  end

  def pick_parent
    while true
      i = @pick_index
      @pick_index = ( @pick_index + 1 ) % @gen_size
      if rand < @score_diff[i] / @max_score
        @picked[i] += 1
        # $log.debug("Picked parent #{i} (score #{@score_diff[i]})") if $debug_breed
        return @generation[i]
      end
    end
  end
  
  def control
    previous = $debug_breed
    $debug_breed = false
    num_control_games = 30
    $log.debug("Playing #{num_control_games} games to measure the current winner against our control AI...")
    total_score = num_wins = num_wins_w = 0
    num_control_games.times do
      score = play_game("control","winner",@control_genes,@winner)
      score_w = play_game("winner","control",@winner,@control_genes)
      num_wins += 1 if score>0
      num_wins_w += 1 if score_w<0
      total_score += score - score_w
    end
    $debug_breed = true
    $log.debug("Average score: #{total_score/num_control_games}") if $debug_breed
    $log.debug("Winner genes: #{@winner}") if $debug_breed
    $log.debug("Distance between control and current winner genes: #{'%.02f' % @control_genes.distance(@winner)}") if $debug_breed
    $log.debug("Total score of control against current winner: #{total_score} (out of #{num_control_games*2} games, control won #{num_wins} as black and #{num_wins_w} as white)") if $debug_breed
    $debug_breed = previous
  end

  def control_issue
    @timer.start("control issue",62,410)
    previous = $debug_breed
    $debug_breed = false
    num_control_games = 1000
    $log.debug("Issue black/white unbalance. Playing #{num_control_games} games to measure the current winner against our control AI...")
    total_score = num_wins = num_wins_w = 0
    num_control_games.times do
      score = play_game("control","control",@control_genes,@control_genes)
      num_wins += 1 if score>0
      raise "tie game?!" if score == 0
      total_score += score
    end
    @timer.stop(false)
    $debug_breed = true
    $log.debug("Average score of control against itself: #{total_score/num_control_games}") if $debug_breed
    $log.debug("Total score: #{total_score} (out of #{num_control_games} games, control won #{num_wins} as black; should be half = #{num_control_games/2}; we usually get 4.2 instead of 5 wins)") if $debug_breed
    $debug_breed = previous
  end

end

opts = Trollop::options do
  opt :size, "Goban size", :default => 9
end

breeder = Breeder.new(opts[:size])
breeder.run

