class Player

  attr_reader :goban, :controller, :color, :is_human

  def initialize(is_human, controller)
    @is_human = is_human
    @controller = controller
    @goban = controller.goban
  end
  
  def set_color(color)
    @color = color
  end
  
  def on_undo_request(color)
    true
  end

end
