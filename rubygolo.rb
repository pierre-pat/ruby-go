require_relative "controller"
require_relative "ai1_player"

class Rubygolo
  def Rubygolo.main
    c = Controller.new(9, 2)
    c.set_player(0, Ai1Player.new)
    c.set_player(1, Ai1Player.new)
    c.play_game
  end
end

Rubygolo.main
