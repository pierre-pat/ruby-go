require "socket"

require_relative "controller"
require_relative "ai1_player"
require_relative "human_player"

class MainServer

  def initialize
    @ses = nil
    @controller = nil
  end

  def start
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
    when "/newGame" then new_game()
    when "/move" then new_move(args)
    when "/undo"then command("undo")
    when "/pass"then command("pass")
    when "/resign"then command("resign")
    else ses.print("Unknown request: "+url)
    end
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

  # http://localhost:8080/newGame
  def new_game()
    c = Controller.new(9,2,0)
    c.set_player(0, Ai1Player.new)
    # c.set_player(1, Ai1Player.new)
    # c.set_player(0, HumanPlayer.new)
    c.set_player(1, HumanPlayer.new)
    @controller = c
    @ses.print(web_display(@controller.goban))
  end
  
  def command(cmd)
    @controller.play_one_move(cmd)
    @ses.print(web_display(@controller.goban))
  end
    
  # http://localhost:8080/move?i=3&j=2
  def new_move(args)
    raise "Bad arguments" if args[0]!="at"
    move=args[1]
    @controller.play_one_move(move)
    @ses.print(web_display(@controller.goban))
  end
  
  def web_display(goban)
    size=goban.size
    s=""
    size.downto(1) do |j|
      s << j.to_s
      1.upto(size) do |i|
        cell=goban.stone_at?(i,j)
        if cell==EMPTY
          if Stone.valid_move?(goban,i,j,@controller.cur_color)
            s << "<a href='move?at="+goban.x_label(i)+j.to_s+"'>+</a>"
          else
            s << "+" # empty intersection we cannot play on (ko or suicide)
          end
        else
          s << cell.to_text
        end
      end
      s << "<br>"
    end
    s << "   "
    1.upto(size) { |i| s << goban.x_label(i)+"&nbsp;" }
    s << "<br>"
    s << "<a href='undo'>undo</a> "
    s << "<a href='pass'>pass</a> "
    s << "<a href='resign'>resign</a> "
    return s
  end  

end

# example http://localhost:8080/mainMenu?par1=val1

server=MainServer.new
server.start

