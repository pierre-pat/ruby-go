require_relative "player"

class HumanPlayer < Player

  def initialize
    @resigned = false
  end
  
  def get_move
    return "pass" if @resigned
    @goban.display
    loop do
      puts "What is "+Stone.color_name(@color)+"'s move?"
      move = gets.downcase.strip
      if move == "resign"
        @resigned = true
        break
      elsif move == "pass"
        break
      else
        col,row = Goban.parse_move(move)
        break if @goban.valid_move?(col, row, @color)
        puts "Invalid move: "+move
      end
    end
    puts "Your move: "+move
    return move
  end
end
