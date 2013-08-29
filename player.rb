class Player

  attr_reader :goban, :controller, :color, :is_human

  def initialize(is_human, controller, color)
    @is_human = is_human
    @controller = controller
    @color = color
    @goban = controller.goban
  end
  
  def on_undo_request(color)
    true
  end

end
