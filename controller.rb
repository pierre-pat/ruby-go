require_relative "goban"
require_relative "stone"
require_relative "human_player"

class Controller
  attr_reader :goban, :cur_color, :history
  
  def initialize(size, num_players)
    Stone.init(num_players)
    @goban = Goban.new(size)
    @num_colors = num_players
    @num_pass = 0
    #TODO handicap - black first unless handicap
    @cur_color = 0
    @players = []
    num_players.times {|p| set_player(p,HumanPlayer.new)}
    @history = []
  end
  
public
  #Sets a player before the game starts
  def set_player(color, player)
    @players[color] = player
    player.attach_to_game(self,color)
  end

  def play_game
    loop do
      player = @players[@cur_color]
      move = player.get_move
      @history[@history.size] = Stone.color_name(@cur_color)+": "+move
      if move == "pass" or move == "resign"
        @num_pass += 1
        break if @num_pass == @num_colors
      else
        @num_pass = 0
        @goban.play(move,@cur_color);
      end
      @cur_color = (@cur_color+1) % @num_colors
    end
    end_game
  end

private
  def end_game
    @goban.display_score
    @history.each {|m| puts m}
  end 
end
