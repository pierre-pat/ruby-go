require_relative "player"

class HumanPlayer < Player

  def initialize
    @resigned = false
  end
  
  def get_move
    return "pass" if @resigned
    @goban.console_display
    move = nil
    loop do
      puts "What is "+Stone.color_name(@color)+"'s move?"
      move = gets.downcase.strip
      if move == "resign"
        @resigned = true
        break
      elsif move == "pass"
        break
      elsif move == "undo"
        return "undo"
      else
        col,row = Goban.parse_move(move)
        break if Stone.valid_move?(@goban, col, row, @color)
        puts "Invalid move: "+move
      end
    end
    # puts "Your move: "+move
    return move
  end
  
  def on_undo_request(color)
    puts "Undo requested by "+Stone.color_name(color)+", do you accept? (y/n)"
    answer = gets.downcase.strip
    return answer == "y"
  end
end
