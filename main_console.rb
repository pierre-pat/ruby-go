require 'trollop'

require_relative "logging"
require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"

opts = Trollop::options do
  opt :size, "Goban size", :default => 9
  opt :players, "Number of players", :default => 2
  opt :ai, "AI plays black"
  opt :handicap, "Number of handicap stones", :default => 0
  opt :load, "Game to load like e4,c3,d5", :type => :string
end

puts opts

# Create controller & players
c = Controller.new(opts[:size], opts.players, opts.handicap)
first_human = 0
if opts.ai
  c.set_player(0, Ai1Player)
  first_human = 1
end
first_human.upto(opts.players-1) { |n| c.set_player(n, HumanPlayer) }

c.play_moves(opts.load) if opts.load

# Start the game
c.play_console_game
