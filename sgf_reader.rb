# Example:
# (;FF[4]EV[go19.ch.10.4.3]PB[kyy]PW[Olivier Lombart]KM[6.5]SZ[19]
# SO[http://www.littlegolem.com];B[pd];W[pp];
# B[ce];W[dc]...;B[tt];W[tt];B[tt];W[aq])

require_relative "logging"


class SgfReader

  attr_reader :board_size, :komi, :handicap, :handicap_stones

  def initialize(sgf)
    @text = sgf
    @nodes = []
    @board_size = 19
    @handicap = 0
    @handicap_stones = []
    @komi = 6.5
    parse_game_tree(sgf)
    get_game_info
  end

  # Raises an exception if we could not convert the format
  def to_move_list
    # NB: we verify the expected player since our internal move format
    # does not mention the player each time.
    expected_player = "B"
    moves = ""
    if @handicap > 0
      expected_player = "W"
      if @handicap_stones.size != 0
        raise "List of #{@handicap_stones.size} handicap stones given does not match the handicap number of #{@handicap}" if @handicap_stones.size != @handicap
        moves = "hand:#{@handicap}=#{@handicap_stones.join("-")},"
      else
        moves = "hand:#{@handicap},"
      end
    end
    1.upto(@nodes.size-1) do |i|
      name = @nodes[i][0]
      value = @nodes[i][1]
      if name != "B" and name != "W"
        $log.warn("Unknown property #{name}[#{value}] ignored") if name != "C" # comments can be ignored
        next
      end
      raise "Move for #{expected_player} was expected and we got #{name} instead" if name != expected_player
      moves << "#{convert_move(value)},"
      expected_player = (expected_player == "B" ? "W" : "B")
    end
    return moves.chop!
  end

private

  def get_game_info
    header = @nodes[0]
    raise "SGF header missing" if ! header or header[0] != "FF"
    0.step(header.size-1,2) do |p|
      name = header[p]
      val = header[p+1]
      case name
      when "FF" then $log.warn("SGF version FF[#{val}]. Not sure we handle it.") if val.to_i<4
      when "SZ" then @board_size = val.to_i
      when "HA" then @handicap = val.to_i
      when "AB" then @handicap_stones.push(convert_move(val))
      when "KM" then @komi = val.to_f
      when "RU","RE","PB","PW","BR","WR","BT","WT","TM","DT","EV","RO",
        "PC","GN","ON","GC","SO","US","AN","CP" then nil
      else $log.info("Unknown property in SGF header: #{name}[#{val}]")
      end
    end
  end

  def convert_move(sgf_move)
    if sgf_move == "tt"
      move = "pass"
    else
      move = sgf_move[0] + (@board_size - (sgf_move[1].ord - "a".ord)).to_s
    end
    return move
  end

  def parse_game_tree(t)
    skip(t)
    get("(",t)
    parse_node(t)
    while parse_node(t) do end
    get(")",t)
  end

  def parse_node(t)
    skip(t)
    return false if t[0]!=";"
    get(";",t)
    node = []
    while true
      i = 0
      while t[i] and t[i].between?("A","Z") do i += 1 end
      prop_ident = t[0,i]
      error("Property name expected",t) if prop_ident == ""
      node.push(prop_ident)
      get(prop_ident,t)
      while true
        get("[",t)
        brace = t.index("]")
        error("Missing ']'",t) if ! brace
        val = t[0,brace]
        node.push(val)
        get(val+"]",t)
        break if t[0] != "["
        node.push(nil) # multiple values, we use nil as name for 2nd, 3rd, etc.
      end
      break if ! t[0] or ! t[0].between?("A","Z")
    end
    @nodes.push(node)
    return true
  end

  def skip(t)
    t.lstrip!
  end
  
  def get(lex,t)
    error("#{lex} expected",t) if ! t.start_with?(lex)
    t.sub!(lex,"")
    t.lstrip!
  end
  
  def error(reason,t)
    raise "Syntax error: '#{reason}' at ...#{t[0,20]}..."
  end

end
