require_relative "player"

class Ai1Player < Player

  def initialize
    @row = 2
    @col = 4
  end

  def get_move
    #TODO cleverer AI
    loop do
      @row += 1
      break if @goban.valid_move?(@col, @row, @color)
      return "pass" if @row > @goban.size
    end
    move = Goban.move_as_string(@col, @row)
    return move
  end
end
