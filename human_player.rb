require_relative "player"

class HumanPlayer < Player

  def initialize(controller, color)
    super(true, controller, color)
  end
  
  # For humans this is only called for console game
  def get_move
    @goban.console_display
    puts "What is #{@goban.color_name(@color)}'s move? (#{@goban.color_to_char(@color)})"
    return get_answer
  end
  
  def on_undo_request(color)
    return true # TODO: until we implement how to broadcast this to web UI
    # puts "Undo requested by #{@goban.color_name(color)}, do you accept? (y/n)"
    # return get_answer(["y","n"]) == "y"
  end
  
  def propose_score()
    @controller.analyser.debug_dump
    @controller.show_score_info
    puts "Do you accept this score? (y/n)"
    return get_answer(["y","n"]) == "y"
  end

private

  def get_answer(valid_ones=nil)
    while true do
      answer = gets.downcase.strip
      next if answer == ""
      if valid_ones and ! valid_ones.find_index(answer)
        puts "Valid answers: "+valid_ones.join(",")
        next
      end
      return answer
    end

  end
  
end
