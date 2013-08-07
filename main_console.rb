require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"

c = Controller.new(9,2,0)
# c.set_player(0, Ai1Player.new)
# c.set_player(1, Ai1Player.new)
c.set_player(0, HumanPlayer.new)
c.set_player(1, HumanPlayer.new)
c.play_console_game
