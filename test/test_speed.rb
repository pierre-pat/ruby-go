require 'test/unit'

require_relative "../logging"
$debug = false # if true it takes forever...
$log.level=Logger::ERROR
require_relative "time_keeper"

require_relative "../controller"
require_relative "../human_player"

$count = 0

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

  # Not very fancy: add the line $count += 1 wherever you want to count.
  # Need some time to try a good profiler soon...
  def show_count
    if $count != 0
      puts "Code called #{$count} times"
      $count = 0
    end
  end

  def test_speed
    tolerance = 1.20

    # prepare games so we isolate the GC caused by that 
    # (in real AI thinking there will be many other things but...)
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
    game1 = "c3,f3,d7,e5,c5,f7,e2,e8,d8,f2,f1,g1,e1,h2,e3,d4,e4,f4,d5,d3,d2,c2,c4,d6,e7,e6,c6,f8,e9,f9,d9,c7,c8,b8,b7"
    game1_moves_ij = moves_ij(game1)

    t = TimeKeeper.new(tolerance)
    t.calibrate

    t.start("100,000 stones (no validation) and undo", 3.84, 11)
    1.upto(10000) do
      play_10_stones
    end
    t.stop
    show_count

    t.start("35 move game, 2000 times and undo", 4.60, 39)
    1.upto(2000) do
      play_game_and_clean(game1_moves_ij)
    end
    t.stop
    show_count

    # The idea here is to verify that undoing things is cheaper than throwing it all to GC
    # In a tree exploration strategy the undo should be the only way (otherwise we quickly hog all memory)
    t.start("35 move game, 2000 times new board each time", 4.87, 26)
    1.upto(2000) do
      play_game_and_clean(game1_moves_ij,false)
    end
    t.stop
    show_count
  end
  
  # Converts "a1,b2" in [1,1,2,2]
  def moves_ij(game)
    return game.split(",").collect_concat { |m| Goban.parse_move(m) }
  end

  def play_moves(moves_ij)
    move_count = 0
    cur_color = BLACK
    0.step(moves_ij.size - 2, 2) do |n|
      i = moves_ij[n]
      j = moves_ij[n+1]
      raise "Invalid move generated: #{move}" if !Stone.valid_move?(@goban, i, j, cur_color)
      Stone.play_at(@goban, i, j, cur_color)
      move_count += 1
      cur_color = (cur_color+1) % 2
    end
    return move_count
  end

  def play_game_and_clean(moves_ij, with_undo=true)
    num_moves = moves_ij.size/2
    assert_equal(num_moves, play_moves(moves_ij))

    if with_undo then
      1.upto(num_moves) { Stone.undo(@goban) }
    else
      init_board()
    end
    assert_equal(nil, @goban.previous_stone)
  end
  
  # Our first, basic test
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
  
end
