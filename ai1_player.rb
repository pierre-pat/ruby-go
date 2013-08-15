require_relative "player"
require_relative "stone"

# TODO AI (this one just plays a few stones and then passes forever)
class Ai1Player < Player

  def initialize(controller, color)
    super(false, controller, color)
    @row = 2
    @col = 4
  end

  def get_move
    loop do
      @row += 1
      break if Stone.valid_move?(@goban, @col, @row, @color)
      return "pass" if @row > @goban.size
    end
    move = Goban.move_as_string(@col, @row)
    return move
  end
end
