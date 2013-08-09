require_relative "player"
require_relative "stone"

class Ai1Player < Player

  def initialize
    @is_human = false
    @row = 2
    @col = 4
  end

  def get_move
    # TODO cleverer AI
    loop do
      @row += 1
      break if Stone.valid_move?(@goban, @col, @row, @color)
      return "pass" if @row > @goban.size
    end
    move = Goban.move_as_string(@col, @row)
    return move
  end
end
