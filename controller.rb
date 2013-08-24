require_relative "goban"
require_relative "board_analyser.rb"

# A controller initializes a game and controls the possible user (or AI) actions.
class Controller
  attr_reader :goban, :analyser, :cur_color, :history, :messages, :game_ended, :game_ending
  
  def initialize(size, num_players=2, handicap=0)
    @goban = Goban.new(size,num_players)
    @analyser = BoardAnalyser.new(@goban)
    @console = false
    @num_colors = num_players
    @num_pass = 0
    @cur_color = BLACK
    @game_ended = @game_ending = false
    @who_resigned = nil
    @history = []
    @messages = []
    @players = Array.new(num_players,nil)
    @handicap = 0
    set_handicap_points(handicap) if handicap>0
  end
  
  # Sets a player before the game starts
  def set_player(color, player_class)
    @players[color] = player_class.new(self,color)
    $log.info("Attached new player to game: #{color}, #{@players[color]}")
  end
  
  # game is a series of moves, e.g. "c2,b2,pass,b4,b3,undo,b4,pass,b3"
  def play_moves(game)
    game.split(",").each { |move| play_one_move(move) }
  end
  
  def add_message(msg)
    if ! @console then @messages.push(msg) else puts msg end
  end

  # Handles a regular move + the special commands
  def play_one_move(move)
    return if @game_ended
    $log.debug("Controller playing move #{move}") if $debug
    if move == "help" then
      add_message "Move (e.g. b3) or pass, undo, resign, history, dbg"
      add_message "Four letter abbreviations are accepted, e.g. \"hist\" is valid to mean \"history\""
    elsif move == "undo"
      @num_pass = 0 if request_undo()
    elsif move.start_with?("hist")
      show_history
    elsif move == "dbg" then
      show_debug_info
    elsif move.start_with?("resi")
      resign_request
    elsif move == "pass"
      pass_one_move
    elsif move.start_with?("pris")
      show_prisoners
    else
      play_a_stone(move)
    end
  end

  # Handles a new stone move (not special commands like "pass")
  def play_a_stone(move)
    i, j = Goban.parse_move(move)
    raise "Invalid move: #{move}" if !Stone.valid_move?(@goban, i, j, @cur_color)
    Stone.play_at(@goban, i, j, @cur_color)
    store_move_in_history(move)
    next_player!
    @num_pass = 0
  end
  
  def pass_one_move
    store_move_in_history("pass")
    @num_pass += 1
    we_all_pass! if @num_pass >= @num_colors
    next_player!
  end
  
  def resign_request
    if @num_colors == 2 then 
      @game_ended = true
      store_move_in_history("resign")
      @who_resigned = @cur_color
    else
      pass_one_move # if more than 2 players one cannot simply resign (but pass infinitely)
    end
  end
  
  def next_player!
    @cur_color = (@cur_color+1) % @num_colors
  end
  
  def play_console_game
    raise "Missing player" if @players.find_index(nil)
    @console = true
    while ! @game_ended
      if @game_ending
        propose_console_end
        next
      end
      player = @players[@cur_color]
      move = player.get_move
      begin
        play_one_move(move)
      rescue StandardError => err
        raise if ! err.to_s.start_with?("Invalid move")
        add_message "Invalid move: \"#{move}\""
      end
    end
    add_message "Game ended."
    show_history
  end

  def let_ai_play
    return nil if @game_ending or @game_ended
    player = @players[@cur_color]
    return nil if player.is_human
    $log.debug("controller letting AI play...") if $debug
    move = player.get_move
    play_one_move(move)
    return move     
  end
  
  def next_player_is_human?
    return @players[@cur_color].is_human
  end

  def show_history
    add_message "Move history:"
    s = ""
    s << "handicap:#{@handicap}," if @handicap>0
    @history.size.times {|h| s << "#{@history[h]}," }
    s.chop!
    add_message s if s != ""
    add_message "(#{@history.size} moves)"
    add_message ""
  end
  
  def show_debug_info
    @goban.debug_display
    @analyser.debug_dump
    add_message "Debug output generated on console window." if ! @console
  end

  # Show prisoner counts during the game  
  def show_prisoners
    prisoners = Group.prisoners?(@goban)
    prisoners.size.times do |c|
      add_message "#{prisoners[c]} #{@goban.color_name(c)} (#{@goban.color_to_char(c)}) are prisoners"
    end
    add_message ""
  end
  
  def show_score_info
    if @who_resigned
      add_message "#{@goban.color_name(@who_resigned)} resigned"
    end
    scores = @analyser.scores
    prisoners = @analyser.prisoners
    # Counts prisoners
    scores.size.times do |c| 
      add_message "#{@goban.color_name(c)} (#{@goban.color_to_char(c)}): #{scores[c]-prisoners[c]} points (#{scores[c]} - #{prisoners[c]} prisoners)"
    end
    add_message ""
  end

  def accept_score(answer)
    answer.strip.downcase!
    if answer!="y" and answer!="n"
      add_message "Valid answer is y or n"
      return
    end
    if answer == "n"
      @game_ending = false
      @analyser.restore
      return
    end
    @game_ended = true
  end

private

  def store_move_in_history(move)
    @history.push(move)
  end
  
  def request_undo
    if @history.size < @num_colors
      add_message "Nothing to undo"
      return false
    end
    @players.each do |p|
      if p.color != @cur_color and !p.on_undo_request(@cur_color)
        add_message "Undo denied by #{@goban.color_name(p.color)}"
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

  def we_all_pass!
    @analyser.count_score
    @game_ending = true
  end
  
  def propose_console_end
    player = @players[@cur_color]
    # We ask human players; AI always accepts (since it passed)
    if ! player.is_human or player.propose_score
      @game_ended = true
      return true
    end
    # Ending refused, we will keep on playing
    @analyser.restore
    @game_ending = false
    return false
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
    @handicap = count # keep for later
  end

end
