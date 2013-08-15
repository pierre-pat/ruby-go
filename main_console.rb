require_relative "logging"
require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"

c = Controller.new(9,2,0)
# c.set_player(0, Ai1Player)
# c.set_player(1, Ai1Player)
c.set_player(0, HumanPlayer)
c.set_player(1, HumanPlayer)
c.play_console_game
