# Exemple of URL to start a new game:
# http://localhost:8080/newGame?size=9&players=2&ai=1&handicap=5
# Or a1=0 for 2 human players

require "socket"

require_relative "logging"
require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"

class MainServer

  def initialize
    @ses = nil
    @controller = nil
  end

  def start
    $log.info("Starting the server...")
    webserver = TCPServer.new("localhost",8080)
    while(ses = webserver.accept)
      # for HTML answer
      ses.print "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n"
      handle_request(ses)
      ses.close
    end
  end
  
  def handle_request(ses)
    @ses = ses
    req = ses.gets
    puts "Request received (1st line): "+req
    url,args = parse_request(req)
    case url
      when "/newGame" then new_game(args)
      when "/move" then new_move(args)
      when "/undo" then command("undo")
      when "/pass" then command("pass")
      when "/resign" then command("resign")
      when "/continue" then nil
      when "/history" then command("history")
      when "/dbg" then command("dbg")
      else ses.print("Unknown request: "+url)
    end
    ai_played = @controller.let_ai_play
    @ses.print(web_display(@controller.goban,ai_played))
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
    @controller.play_one_move(move)
  end
  
  def web_display(goban,ai_played)
    ended = @controller.game_ended
    human = (!ended and @controller.next_player_is_human?)
    size=goban.size
    s="<html><head>"
    s << "<style>body {font-size:12pt;} a:link {text-decoration:none} "
    s << "table {border: 1px solid black;} td {width: 15px;}</style>"
    s << "</head><body><table style='{a:link {text-decoration:none}}'>"
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
      s << "Game ended"
    else
      s << " <a href='continue'>continue</a> "
    end
    while txt = @controller.messages.shift do s << "<br>"+txt end
    s << "</body></html>"
    return s
  end

end

server=MainServer.new
server.start

