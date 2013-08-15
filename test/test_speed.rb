require 'test/unit'

require_relative "../logging"
$debug = false # if true it takes forever...
$log.level=Logger::ERROR
require_relative "test_timer"

require_relative "../controller"
require_relative "../human_player"

class TestSpeed < Test::Unit::TestCase

  def init_board(size=9, num_players=2, handicap=0)
    @controller = Controller.new(size, num_players, handicap)
    @controller.set_player(0, HumanPlayer)
    @controller.set_player(1, HumanPlayer)
    @goban = @controller.goban
  end

  def initialize(x)
    super(x)
    init_board()
  end

  def test_speed
    t = TestTimer.new
    t.calibrate

    t.start("100,000 stones and undo", 3.84, 9)
    1.upto(10000) do
      play_10_stones
    end
    t.stop

    t.start("35 move game, 2000 times and undo", 4.54, 45)
    1.upto(2000) do
      play_game_1
    end
    t.stop

    t.start("35 move game, 2000 times new board each time", 4.87, 22)
    1.upto(2000) do
      play_game_1(false)
    end
    t.stop
  end

  def play_10_stones
    Stone.play_at(@goban, 2, 2, WHITE)
    Stone.play_at(@goban, 1, 2, BLACK)
    Stone.play_at(@goban, 1, 3, WHITE)
    Stone.play_at(@goban, 2, 1, BLACK)
    Stone.play_at(@goban, 1, 1, WHITE)
    Stone.play_at(@goban, 4, 4, BLACK)
    Stone.play_at(@goban, 4, 5, WHITE)
    Stone.play_at(@goban, 1, 2, BLACK)
    Stone.play_at(@goban, 5, 5, WHITE)
    Stone.play_at(@goban, 5, 4, BLACK)
    1.upto(10) { Stone.undo(@goban) }
  end
  
  def play_game_1(with_undo=true)
    # 35 moves, final position:
    # 9 +++OO@+++
    # 8 +@OO@@+++
    # 7 +O+OO@+++
    # 6 ++O@@++++
    # 5 ++OO@++++
    # 4 ++O+O@+++
    # 3 ++O+O@+++
    # 2 ++@OO@+@+
    # 1 ++++OO@++
    #   abcdefghi
    @controller.play_moves("c3,f3,d7,e5,c5,f7,e2,e8,d8,f2,f1,g1,e1,h2,e3,d4,e4,f4,d5,d3,d2,c2,c4,d6,e7,e6,c6,f8,e9,f9,d9,c7,c8,b8,b7")
    if with_undo then
      1.upto(35) { Stone.undo(@goban) }
    else
      init_board()
    end
  end
  
end
