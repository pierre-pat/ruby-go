# Exemple of URL to start a new game:
# http://localhost:8080/newGame?size=9&players=2&ai=1&handicap=5
# Or a1=0 for 2 human players

require "socket"

require_relative "logging"
require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"

# Very simple server that can be used to play a single *local* game
# using a web browser as GUI.
class MainServer

  INDEX_PAGE = "./help-index.html"
  PORT = 8080

  def initialize
    @controller = nil
    @webserver = nil
    @session = nil
  end
  
  def start
    $log.info("Starting the server...")
    puts "Please open a web browser on http://localhost:#{PORT}/index"
    @webserver = TCPServer.new("localhost",PORT)
    loop do
      req = get_session_and_request
      reply = handle_request(req)
      send_response(reply)
    end
  end

  def get_session_and_request
    begin
      if @session == nil
        @session = @webserver.accept
        # With IE, the first request is empty so we will raise, rescue, close and reopen. Not sure why...
        @session.recv_nonblock(5,Socket::MSG_PEEK) # raises Errno::EWOULDBLOCK if no data
        $log.info("Got session: #{@session}")
      end
      raise "Connection dropped" if ! (req = @session.gets)
    rescue => err
      if err.class.name == "Errno::EWOULDBLOCK"
        $log.debug("Closing and reopening the session...") # see comment above about IE
      elsif err.class.name == "Errno::ECONNRESET" or err.message == "Connection dropped" # connection dropped or closed by the remote host
        $log.info("Connection dropped or timed-out; we will create a new session (no issue)")        
      else
        $log.error("Unexpected error: #{err.class}, msg:#{err.message}")
      end
      close_session
      retry
    end
    $log.debug("Request received: \"#{req}\"") if $debug
    @keep_alive = false
    while("" != (r = @session.gets.chop)) do
      $log.debug("...\"#{r}\"") if $debug
      @keep_alive = true if /Connection:[ ]*Keep-Alive/ === r
    end
    return req.chop
  end

  def close_session
    @session.close
    @session = nil
  end
  
  def send_response(reply)
    header = response_header?(reply)
    begin
      @session.print header
      @session.print reply # can throw Broken pipe (Errno::EPIPE)
      close_session if ! @keep_alive
    rescue => err
      $log.error("Unexpected error: #{err.class}, msg:#{err.message}") 
      close_session # always close after error here
    end
  end
  
  def response_header?(reply)
    header = "HTTP/1.1 200 OK\r\n"
    header<< "Date: #{Time.now.ctime}\r\n"
    header<< if @keep_alive then "Connection: Keep-Alive\r\n" else "Connection: close\r\n" end
    header<< "Server: local Ruby\r\n"
    header<< "Content-Type: text/html; charset=UTF-8\r\nContent-Length: #{reply.length}\r\n\r\n"
    $log.debug("Header returned:\r\n#{header}") if $debug
    return header
  end
  
  def handle_request(req)
    url,args = parse_request(req)
    if ! @controller and url != "/newGame" and url != "/index"
      return "Invalid request before starting a game: #{url}"
    end
    reply = ""
    case url
      when "/newGame" then new_game(args)
      when "/move" then new_move(args)
      when "/undo" then command("undo")
      when "/pass" then command("pass")
      when "/resign" then command("resign")
      when "/continue" then nil
      when "/history" then @controller.show_history
      when "/dbg" then @controller.show_debug_info
      when "/index" then return File.read(INDEX_PAGE)
      else reply << "Unknown request: #{url}"
    end
    ai_played = @controller.let_ai_play
    reply << web_display(@controller.goban,ai_played)
    return reply
  end
  
  def parse_request(req_str)
    # GET /mainMenu?par1=val1 HTTP/1.1
    reqs = req_str.split()
    raise "Unsupported request: "+req if reqs.size<3 or reqs[0]!="GET" or reqs[2]!="HTTP/1.1"
    full_url = reqs[1]
    url,arg_str = full_url.split("?")
    if arg_str then args=arg_str.split(/&|=/) end
    return url,args
  end

  def get_arg(args, name, def_val=nil)
    ndx = args ? args.index(name) : nil
    return args[ndx+1] if ndx
    raise "Missing argument "+name if !def_val
    return def_val
  end
  
  def get_arg_i(args, name, def_val=nil)
    return get_arg(args,name,def_val).to_i
  end

  # http://localhost:8080/newGame?size=9&players=2&handicap=0&ai=0
  def new_game(args)
    size = get_arg_i(args,"size",19)
    num_players = get_arg_i(args,"players",2)
    handicap = get_arg_i(args,"handicap",0)
    num_ai = get_arg_i(args,"ai",1)
    @controller = Controller.new(size,num_players,handicap)
    1.upto(num_players) do |n|
      @controller.set_player(n-1, num_ai>=n ? Ai1Player : HumanPlayer)
    end
  end
  
  def command(cmd)
    @controller.play_one_move(cmd)
  end
    
  # http://localhost:8080/move?at=b3
  def new_move(args)
    move=get_arg(args,"at")
    begin
      @controller.play_one_move(move)
    rescue RuntimeError => err
      raise if ! err.message.start_with?("Invalid move")
      @controller.add_message("Ignored move #{move} because the game displayed was not the latest one.")
    end
  end
  
  def web_display(goban,ai_played)
    ended = @controller.game_ended
    human = (!ended and @controller.next_player_is_human?)
    size=goban.size
    s="<html><head>"
    s << "<style>body {background-color:#f0f0f0; font-family: tahoma, sans serif; font-size:90%} "
    s << "a:link {text-decoration:none; color:#0000FF} a:visited {color:#0000FF} "
    s << "a:hover {color:#00D000} a:active {color:#FFFF00} \n"
    s << "table {border: 1px solid black;} td {width: 15px;}</style>"
    s << "</head><body><table>"
    size.downto(1) do |j|
      s << "<tr><th>"+j.to_s+"</th>"
      1.upto(size) do |i|
        cell=goban.stone_at?(i,j)
        if cell.empty?
          if human and Stone.valid_move?(goban,i,j,@controller.cur_color)
            s << "<td><a href='move?at="+goban.x_label(i)+j.to_s+"'>+</a></td>"
          else
            s << "<td>+</td>" # empty intersection we cannot play on (ko or suicide)
          end
        else
          s << "<td>"+cell.to_text+"</td>"
        end
      end
      s << "</tr>"
    end
    s << "<tr><td></td>"
    1.upto(size) { |i| s << "<th>"+goban.x_label(i)+"</th>" }
    s << "</tr></table>"
    if ai_played then
      s << "AI played "+ai_played+"<br>"
    end
    if human then
      s << " <a href='undo'>undo</a> "
      s << " <a href='pass'>pass</a> "
      s << " <a href='resign'>resign</a> "
      s << " <a href='history'>history</a> "
      s << " <a href='dbg'>debug</a> "
      s << " <br>Who's turn: "+Stone::COLOR_CHARS[@controller.cur_color]
    elsif ended then
      s << "Game ended. <a href='index'>Back to index</a>"
      @controller.show_history
    else
      s << " <a href='continue'>continue</a> "
    end
    s << "<br>"
    while txt = @controller.messages.shift do s << "<br>"+txt end
    s << "</body></html>"
    return s
  end

end

server=MainServer.new
server.start

