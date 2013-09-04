require 'trollop'

require_relative "logging"
require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"


opts = Trollop::options do
  opt :size, "Goban size", :default => 9
  opt :players, "Number of players", :default => 2
  opt :ai, "How many AI players", :default => 0
  opt :handicap, "Number of handicap stones", :default => 0
  opt :load, "Game to load like e4,c3,d5", :type => :string
end
puts "Command line options received: #{opts}"

# Create controller & players
c = Controller.new
c.new_game(opts[:size], opts.players, opts.handicap)
opts.players.times do |n|
  c.set_player(opts.ai>n ? Ai1Player.new(c,n) : HumanPlayer.new(c,n))
end

c.load_moves(opts.load) if opts.load

# Start the game
c.play_console_game
