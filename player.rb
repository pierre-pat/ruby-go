class Player

  attr_reader :goban, :controller, :color, :is_human

  def initialize
    @is_human = false
  end
  
  def attach_to_game(controller, color)
    @controller = controller
    @goban = controller.goban
    @color = color
  end
  
  def on_undo_request(color)
    true
  end
end
