require_relative "goban"
require_relative "board_analyser"
require_relative "sgf_reader"
require_relative "human_player"

# A controller initializes a game and controls the possible user (or AI) actions.
class Controller
  attr_reader :goban, :analyser, :cur_color, :history, :messages, :game_ended, :game_ending
  
  def initialize
    @console = false
    @history = []
    @messages = []
    @players = []
    @handicap = 0
    @num_colors = 2
  end

  def new_game(size=nil, num_players=@num_colors, handicap=@handicap, komi=nil)
    @analyser.restore if @analyser
    @analyser = nil
    @with_human = false
    @num_autoplay = 0
    @history.clear
    @messages.clear
    @num_pass = 0
    @cur_color = BLACK
    @game_ended = @game_ending = false
    @who_resigned = nil
    if ! @goban or ( size and size != @goban.size ) or num_players != @goban.num_colors
      @goban = Goban.new(size,@num_colors)
    else
      @goban.clear
    end
    @komi = (komi ? komi : (handicap == 0 ? 6.5 : 0.5))
    set_handicap(handicap)
    @players.clear if num_players != @num_colors
    @num_colors = num_players
  end
  
  # Sets a player before the game starts
  def set_player(player)
    color = player.color
    @players[color] = player
    # $log.info("Attached new player to game: #{color}, #{player}")
    @with_human = true if player.is_human
  end
  
  # game is a series of moves, e.g. "c2,b2,pass,b4,b3,undo,b4,pass,b3"
  def load_moves(game)
    begin
      game = sgf_to_game(game)
      game.split(",").each { |move| play_one_move(move) }
    rescue => err
      add_message "Oops... Something went wrong with the loaded moves..."
      add_message "Please double check the format of your input."
      add_message "Error: #{err.message} (#{err.class.name})"
      $log.error("Error while loading moves:\n#{err}\n#{err.backtrace}")
    end
  end

  # Converts a game (list of moves) from SGF format to our internal format.
  # Returns the game unchanged if it is not an SGF one.
  # Returns an empty move list if nothing should be played (a game is pending).
  def sgf_to_game(game)
    return game if ! game.start_with?("(;FF") # are they are always the 1st characters?
    if history.size > 0
      add_message "A game is pending. Please start a new game before loading an SGF file."
      return ""
    end
    reader = SgfReader.new(game)
    new_game(reader.board_size, 2, reader.handicap)
    @komi = reader.komi
    return reader.to_move_list
  end
  
  def add_message(msg)
    if ! @console then @messages.push(msg) else puts msg end
  end

  # Handles a regular move + the special commands
  def play_one_move(move)
    return if @game_ended
    # $log.debug("Controller playing #{@goban.color_name(@cur_color)}: #{move}") if $debug
    if /^[a-z][1-2]?[0-9]$/ === move
      play_a_stone(move)
    elsif move == "help" then # this help is for console only
      add_message "Move (e.g. b3) or pass, undo, resign, history, dbg, log:(level)=(1/0), load:(moves), continue:(times)"
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
    elsif move.start_with?("hand")
      set_handicap(move.split(":")[1])
    elsif move.start_with?("load:")
      load_moves(move[5..-1])
    elsif move.start_with?("cont")
      @num_autoplay = move.split(":")[1].to_i
      @num_autoplay = 1 if @num_autoplay == 0 # no arg is equivalent to continue:1
    elsif move.start_with?("log")
      set_log_level(move.split(":")[1])
    else
      add_message "Invalid command: #{move}"
    end
  end

  # Handles a new stone move (not special commands like "pass")
  def play_a_stone(move)
    i, j = Goban.parse_move(move)
    raise "Invalid move: #{move}" if !Stone.valid_move?(@goban, i, j, @cur_color)
    @players[@cur_color].get_ai_eval(i,j) if $debug and @players[@cur_color].is_human
    Stone.play_at(@goban, i, j, @cur_color)
    store_move_in_history(move)
    next_player!
    @num_pass = 0
  end
  
  def pass_one_move
    store_move_in_history("pass")
    @num_pass += 1
    we_all_pass if @num_pass >= @num_colors
    next_player!
  end
  
  def resign_request
    if @num_colors == 2 then 
      @game_ended = true
      store_move_in_history("resign")
      @who_resigned = @cur_color # TODO: make it work for multiplayer mode too
    else
      pass_one_move # if more than 2 players one cannot simply resign (but pass infinitely)
    end
  end
  
  def next_player!
    @cur_color = (@cur_color+1) % @num_colors
  end
  
  # Returns the score difference in points
  def play_breeding_game
    @console = true
    while ! @game_ending
      move = @players[@cur_color].get_move
      begin
        play_one_move(move)
      rescue StandardError => err
        puts "Exception occurred during a breeding game.\n#{@players[@cur_color]} with genes: #{@players[@cur_color].genes}"
        show_history
        raise
      end
    end
    score_diff = compute_two_player_score(@analyser.scores, @analyser.prisoners)
    @analyser.restore
    return score_diff
  end
  
  def play_console_game
    raise "Missing player" if @players.find_index(nil)
    @human = HumanPlayer.new(self,-1) if ! @with_human
    @num_autoplay = 0
    @console = true
    while ! @game_ended
      if @game_ending
        propose_console_end
        next
      end
      player = @players[@cur_color]
      if @with_human or @num_autoplay > 0
        move = player.get_move
        @num_autoplay -= 1
      else
        move = @human.get_move
      end
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
  
  def history_str
    return @history.join(",")
  end
  
  def show_debug_info
    @goban.debug_display
    @analyser.debug_dump if @analyser
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
    else
      scores = @analyser.scores
      prisoners = @analyser.prisoners
      if @num_colors == 2
      then show_two_player_score(scores,prisoners)
      else show_multiplayer_score(scores,prisoners) end
    end
    add_message ""
  end

  # Returns the score difference in points
  def show_two_player_score(scores,prisoners)
    return compute_two_player_score(scores,prisoners,true)
  end
  
  # Returns the score difference in points
  def compute_two_player_score(scores,prisoners,output=false)
    totals = []
    2.times do |c|
      komi = (c == WHITE ? @komi : 0)
      totals[c] = scores[c] + prisoners[1 - c] + komi
      if output
        komi_str = (komi > 0 ? " + #{komi} komi" : "")
        add_message "#{@goban.color_name(c)} (#{@goban.color_to_char(c)}): "+
          "#{totals[c]} points (#{scores[c]} + #{prisoners[1 - c]} prisoners#{komi_str})"
      end
    end
    diff = totals[BLACK] - totals[WHITE]
    if output
      win = if diff > 0 then BLACK else WHITE end
      if diff != 0
        add_message "#{@goban.color_name(win)} wins by #{diff.abs} points"
      else
        add_message "Tie game"
      end
    end
    return diff
  end
  
  def show_multiplayer_score(scores,prisoners)
    scores.size.times do |c|
      add_message "#{@goban.color_name(c)} (#{@goban.color_to_char(c)}): "+
        "#{scores[c]-prisoners[c]} points "+
        "(#{scores[c]} - #{prisoners[c]} prisoners)"
    end
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

  def set_log_level(cmd)
    begin
      a = cmd.split("=")
      flag = a[1].to_i != 0
      raise 0 if ! flag and a[1]!="0"
      case a[0]
      when "group" then $debug_group = flag
      when "ai" then $debug_ai = flag
      when "all" then $debug = $debug_group = $debug_ai = flag
      else raise 1
      end
    rescue
      add_message "Invalid log command: #{cmd}"
    end
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

  def we_all_pass
    return if @game_ending # avoid counting score again if nothing changed
    @analyser = BoardAnalyser.new(@goban) if ! @analyser
    @analyser.count_score
    @game_ending = true
  end
  
  def propose_console_end
    player = @players[@cur_color]
    # We ask human players; AI always accepts (since it passed)
    if ! player.is_human or player.propose_score
      if ! player.is_human then @goban.console_display; show_score_info end
      @game_ended = true
      return true
    end
    # Ending refused, we will keep on playing
    @analyser.restore
    @game_ending = false
    return false
  end

  # Initializes the handicap points
  # h can be a number or a string
  # string examples: "3" or "3=d4-p16-p4" or "d4-p16-p4"
  def set_handicap(h)
    raise "Handicap cannot be changed during a game" if history.size > 0
    if h == 0 or h == "0"
      @handicap = 0
      return
    end
    # White first when handicap
    @cur_color = WHITE

    # Standard handicap?
    if h.is_a? String
      eq = h.index("=")
      h = h.to_i if h[0].between?("0","9") and ! eq
    end
    if h.is_a? Fixnum # e.g. 3
      set_standard_handicap(h)
      return
    end

    # Could be standard or not but we are given the stones so use them   
    h = h[eq+1..-1] if eq # "3=d4-p16-p4" would become "d4-p16-p4"
    moves = h.split("-")
    @handicap = moves.size
    moves.each do |move|
      i, j = Goban.parse_move(move)
      Stone.play_at(@goban, i, j, BLACK)
    end
  end
  
  # Places the standard (star points) handicap
  # NB: a handicap of 1 stone does not make sense but we don't really need to care.
  def set_standard_handicap(count)
    # we want middle points only if the board is big enough 
    # and has an odd number of intersections
    size = @goban.size
    count = 4 if (size<9 or size.modulo(2)==0) and count > 4
    @handicap = count
    # Compute the distance from the handicap points to the border:
    # on boards smaller than 13, the handicap point is 2 points away from the border
    dist_to_border=(size<13 ? 2 : 3)
    short = 1 + dist_to_border
    middle = 1 + size/2
    long = size - dist_to_border
    
    count.times do |ndx|
      # Compute coordinates from the index.
      # Indexes correspond to this map (with Black playing on North on the board)
      # 2 7 1
      # 4 8 5
      # 0 6 3
      # special case: for odd numbers and more than 4 stones, the center is picked
      ndx=8 if count.modulo(2)==1 and count>4 and ndx==count-1
      case ndx
      	when 0 then x = short; y = short
      	when 1 then x = long; y = long
      	when 2 then x = short; y = long
      	when 3 then x = long; y = short
      	when 4 then x = short; y = middle
      	when 5 then x = long; y = middle
      	when 6 then x = middle; y = short
      	when 7 then x = middle; y = long
      	when 8 then x = middle; y = middle
      	else break # not more than 8
      end
      Stone.play_at(@goban, x, y, BLACK)
    end
  end

end
