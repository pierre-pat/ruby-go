require 'trollop'

require_relative "logging"
require_relative "time_keeper"
require_relative "controller"
require_relative "ai1_player"

$debug_breed = false # true # TODO move me somewhere else?

class Breeder

  GENERATION_SIZE = 30
  NUM_TOURNAMENTS = 10
  NUM_MATCH_PER_AI_PER_TOURNAMENT = 3
  MUTATION_RATE = 0.05 # e.g. 0.02 is 2%
  WIDE_MUTATION_RATE = 0.20 # how often do we "widely" mutate

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
    @generation = []
    @new_generation = []
    @gen_size.times do |i|
      @generation.push(@player1.genes.clone.mutate_all!)
      @new_generation.push(Genes.new)
    end
    @score_diff = []
  end
  
  # Plays a game and returns the score difference in points
  def play_game(p1,p2)
    # @timer.start("AI VS AI game",0.5,3)
    @controller.new_game(@size)
    @player1.prepare_game(@generation[p1])
    @player2.prepare_game(@generation[p2])
    score_diff = @controller.play_breeding_game
    # @timer.stop(false) # no exception if it takes longer but an error in the log
    $log.debug("\n##{p1}:#{@generation[p1]}\nagainst\n##{p2}:#{@generation[p2]}") if $debug_breed
    $log.debug("Distance: #{'%.02f' % @generation[p1].distance(@generation[p2])}") if $debug_breed
    $log.debug("Score: #{score_diff}") if $debug_breed
    $log.debug("Moves: #{@controller.history_str}") if $debug_breed
    @controller.goban.console_display if $debug_breed
    return score_diff
  end

  def run
    NUM_TOURNAMENTS.times do # TODO: Find a way to appreciate the progress
      @timer.start("Breeding tournament #{NUM_MATCH_PER_AI_PER_TOURNAMENT} games for #{@gen_size} AIs",5.5,36)
      one_tournament
      @timer.stop(false)
      reproduction
    end
    show_winners
  end
  
  def show_winners
    # TODO ?
    # puts "Winner:\n#{@generation[1]}\n against\n#{@generation[0]}"
  end
  
  def one_tournament
    $log.debug("One tournament starts for #{@generation.size} AIs") if $debug_breed
    @gen_size.times { |p1| @score_diff[p1] = 0 }
    @total_diff = 0
    NUM_MATCH_PER_AI_PER_TOURNAMENT.times do
      @gen_size.times do |p1|
        p2 = rand(@gen_size - 1)
        p2 = @gen_size - 1 if p2 == p1
        diff = play_game(p1,p2) * 2
        if diff > 0
          @score_diff[p1] += diff
          @total_diff += diff
        else
          @score_diff[p2] -= diff
          @total_diff -= diff
        end
        $log.debug("Match ##{p1} against ##{p2}; final scores ##{p1}:#{@score_diff[p1]}, ##{p2}:#{@score_diff[p2]}") if $debug_breed
      end
    end
    
    @rank
  end
  
  def reproduction
    $log.debug("=== Reproduction time for #{@generation.size} AI") if $debug_breed
    @picked = Array.new(@gen_size,0)
    @max_score = @score_diff.max
    @winner = @score_diff.find_index(@max_score)
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
  end

  def pick_parent
    while true
      i = @pick_index
      @pick_index = ( @pick_index + 1 ) % @gen_size
      if rand < @score_diff[i] / @max_score
        @picked[i] += 1
        # $log.debug("Picked parent #{i} (score #{@score_diff[i]} / total #{@total_diff})") if $debug_breed
        return @generation[i]
      end
    end
  end

end

opts = Trollop::options do
  opt :size, "Goban size", :default => 9
end

breeder = Breeder.new(opts[:size])
breeder.run

