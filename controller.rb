require_relative "stone_constants"
require_relative "goban"
require_relative "stone"

class Controller
  attr_reader :goban, :cur_color, :history, :messages, :game_ended
  
  def initialize(size, num_players=2, handicap=0)
    Stone.init(num_players)
    @goban = Goban.new(size)
    Group.init(@goban)
    @console = false
    @num_colors = num_players
    @num_pass = 0
    @cur_color = BLACK
    @game_ended = false
    set_handicap_points(handicap) if handicap>0
    @players = Array.new(num_players,nil)
    @history = []
    @messages = []
  end
  
  # Sets a player before the game starts
  def set_player(color, player)
    @players[color] = player
    player.attach_to_game(self,color)
    puts "Attached new player to game: "+color.to_s+", "+player.to_s
  end
  
  def add_message(msg)
    if ! @console then @messages.push(msg) else puts msg end
  end

  def play_one_move(move)
    @history.push(Stone.color_name(@cur_color)+": "+move)
    if move == "resign"
      if @num_colors == 2 then 
        @game_ended = true
        return
      end
      move = "pass" # if more than 2 players one cannot simply resign (but pass infinitely)
    end
    if move == "pass"
      @num_pass += 1
      if @num_pass == @num_colors then
        @game_ended = true
        return
      end      
      @cur_color = (@cur_color+1) % @num_colors
    elsif move == "undo"
      @num_pass = 0 if request_undo()
    else
      @num_pass = 0
      i, j = Goban.parse_move(move)
      raise "Invalid move generated:"+move if !Stone.valid_move?(@goban, i, j, @cur_color)
      Stone.play_at(@goban, i, j, @cur_color)
      @cur_color = (@cur_color+1) % @num_colors
    end
  end
  
  def play_console_game
    raise "Missing player" if @players.find_index(nil)
    @console = true
    loop do
      player = @players[@cur_color]
      move = player.get_move
      play_one_move(move)
      break if @game_ended
    end
    end_game
  end

  def let_ai_play
    player = @players[@cur_color]
    return nil if player.is_human
    move = player.get_move
    play_one_move(move)
    return move     
  end
  
  def next_player_is_human?
    return @players[@cur_color].is_human
  end
  
  def request_undo
    @history.pop # the "undo" command itself never stays in history
    if @history.size < @num_colors
      add_message "Nothing to undo"
      return false
    end
    @players.each do |p|
      if p.color != @cur_color and !p.on_undo_request(@cur_color)
        add_message "Undo denied by "+Stone.color_name(p.color)
        return false
      end
    end
    @num_colors.times do
      Stone.undo(@goban) if ! @history.last.end_with?("pass")
      @history.pop
    end
    add_message "Undo accepted"
    return true
  end

private
  def end_game
    @goban.console_display
    add_message "Game ended. Score: ..."
    # TODO score count and UI; not trivial
    add_message "Move history:"
    @history.each {|m| add_message m}
  end
  
  # Initializes the handicap points
  def set_handicap_points(count)
    size = @goban.size
	  # Compute the distance from the handicap points to the border:
	  # on boards smaller than 13, the handicap point is 2 points away from the border
	  dist_to_border=(size<13 ? 2 : 3)
	  short = 1 + dist_to_border
	  middle = 1 + size/2
	  long = size - dist_to_border

	  # we want middle points only if the board is big enough 
	  # and has an odd number of intersections
	  count = count.max(4) if size<9 or size.modulo(2)==0

    count.times do |ndx|
  	  # Compute coordinates from the index
  	  # indexes correspond to this map:
  	  # 0 4 3
  	  # 6 8 7
  	  # 2 5 1
  	  # special case: for odd numbers and more than 4 stones, the center is picked
  	  ndx=8 if count.modulo(2)==1 and count>4 and ndx==count-1
      case ndx
      	when 0 then x = short; y = short
      	when 1 then x = long; y = long
      	when 2 then x = short; y = long
      	when 3 then x = long; y = short
      	when 4 then x = middle; y = short
      	when 5 then x = middle; y = long
      	when 6 then x = short; y = middle
      	when 7 then x = long; y = middle
      	when 8 then x = middle; y = middle
      	else break # not more than 8
      end
      Stone.play_at(@goban, x, y, BLACK)
    end
    # white first when handicap
    @cur_color = WHITE
  end

end
