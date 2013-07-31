require_relative "controller"

class Player
  def initialize
  end
  
  def attach_to_game(controller, color)
    @controller = controller
    @goban = @controller.goban
    @color = color
  end
end
