require_relative "player"

class HumanPlayer < Player

  def initialize(controller, color)
    super(true, controller, color)
  end
  
  # For humans this is only called for console game
  def get_move
    @goban.console_display
    puts "What is #{Stone.color_name(@color)}'s move? (#{Stone::COLOR_CHARS[@color]})"
    move = ""
    while move == "" do move = gets.downcase.strip end
    return move
  end
  
  def on_undo_request(color)
    return true # TODO: until we implement how to broadcast this to web UI
    puts "Undo requested by "+Stone.color_name(color)+", do you accept? (y/n)"
    answer = gets.downcase.strip
    return answer == "y"
  end
end
