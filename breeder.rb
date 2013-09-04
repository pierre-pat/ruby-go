require 'trollop'

require_relative "logging"
require_relative "time_keeper"
require_relative "controller"
require_relative "ai1_player"

$debug_breed = true # TODO move me somewhere else?

class Breeder

  def initialize(game_size)
    @size = game_size
    @timer = TimeKeeper.new
    @timer.calibrate(0.7)
    c = @controller = Controller.new
    @controller.new_game(@size)
    c.set_log_level("all=0")
    @gen_size = 20
    @mutation_rate = 0.02 # 0.02 is 2%
    @keep_weakest_rate = 0.05 # how many of the weakest do we allow to reproduce anyway
    first_generation
  end

  def first_generation
    @generation = []
    @gen_size.times do |i|
      @generation.push(Ai1Player.new(@controller, i % 2))
    end
  end
  
  def play_game(p1,p2)
    @timer.start("AI VS AI game",0.5,3)
    @controller.new_game(@size)
    @controller.set_player(@generation[p1])
    @controller.set_player(@generation[p2])
    score = @controller.play_breeding_game
    puts "Score: #{score}"
    @timer.stop(false) # no exception if it takes longer but an error in the log
    return score
  end

  def run
    200.times do #TODO: Find a way to appreciate the progress
      one_tournament
      reproduction
    end
    show_winners
  end
  
  def show_winners
    puts "Winner:\n#{@generation[1].genes}\n against\n#{@generation[0].genes}"
    puts "Winner:\n#{@generation[3].genes}\n against\n#{@generation[2].genes}"
    @controller.show_history
  end
  
  def one_tournament
    $log.debug("One tournament starts for #{@gen_size/2} pairs of AI") if $debug_breed
    0.step(@gen_size-1,2) do |p|
      if play_game(p,p+1) >= 0
        # if the winner is black, swap them (so winners have odd numbers)
        swap = @generation[p+1]
        @generation[p+1] = @generation[p]
        @generation[p] = swap
      end
    end
  end
  
  def reproduction
    new_generation = []
    i = 0
    kid1 = Genes.new
    kid2 = Genes.new
    $log.debug("Reproduction time for #{@generation.size} AI") if $debug_breed
    while @generation.size > 0 do
      num_pairs = @generation.size / 2
      pair1 = rand(num_pairs)
      pair2 = rand(num_pairs)
      pair2 = (pair2 + 1) % num_pairs if pair2 == pair1
      weak1 = @generation[pair1*2]
      strong1 = @generation[pair1*2+1]
      weak2 = @generation[pair2*2]
      strong2 = @generation[pair2*2+1]
      parent1 = (rand < @keep_weakest_rate ? weak1.genes : strong1.genes)
      parent2 = (rand < @keep_weakest_rate ? weak2.genes : strong2.genes)
      # remove parents' pair from current generation so we do not select them again
      @generation.delete(weak1)
      @generation.delete(strong1)
      @generation.delete(weak2)
      @generation.delete(strong2)
      
      parent1.mate(parent2, kid1, kid2, @mutation_rate)
      
      # new generation will have 2 parents and 2 kids
      new_generation.push(Ai1Player.new(@controller, i % 2, parent1))
      i += 1
      new_generation.push(Ai1Player.new(@controller, i % 2, parent2))
      i += 1
      new_generation.push(Ai1Player.new(@controller, i % 2, kid1))
      i += 1
      new_generation.push(Ai1Player.new(@controller, i % 2, kid2))
      i += 1
    end
    # now shuffle a bit the new generation so that families mix
    @gen_size.times do
      ndx1 = rand(@gen_size/2)*2 # we shuffle only the black players, it should be enough
      ndx2 = rand(@gen_size/2)*2
      swap = new_generation[ndx1]
      new_generation[ndx1] = new_generation[ndx2]
      new_generation[ndx2] = swap
    end
    @generation = new_generation
  end

end

opts = Trollop::options do
  opt :size, "Goban size", :default => 9
end

breeder = Breeder.new(opts[:size])
breeder.run

