require 'test/unit'

require_relative "../goban"
require_relative "../time_keeper"

require_relative "../logging"
$debug = false # if true it takes forever...
$log.level=Logger::ERROR


$count = 0

class TestSpeed < Test::Unit::TestCase

  def init_board(size=9)
    @goban = Goban.new(size)
  end

  def initialize(test_name)
    super(test_name)
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

  def test_speed1
    tolerance = 1.20
    t = TimeKeeper.new(tolerance)
    t.calibrate(3.2)

    # Basic test
    t.start("Basic (no move validation) 100,000 stones and undo", 3.84, 0)
    10000.times do
      play_10_stones
    end
    t.stop
    show_count

    # prepare games so we isolate the GC caused by that 
    # (in real AI thinking there will be many other things but...)
    # 35 moves, final position:
    # 9 +++@@O+++
    # 8 +O@@OO+++
    # 7 +@+@@O+++
    # 6 ++@OO++++
    # 5 ++@@O++++
    # 4 ++@+@O+++
    # 3 ++@+@O+++
    # 2 ++O@@O+O+
    # 1 ++++@@O++
    #   abcdefghi
    game1 = "c3,f3,d7,e5,c5,f7,e2,e8,d8,f2,f1,g1,e1,h2,e3,d4,e4,f4,d5,d3,d2,c2,c4,d6,e7,e6,c6,f8,e9,f9,d9,c7,c8,b8,b7"
    game1_moves_ij = moves_ij(game1)
    t.start("35 move game, 2000 times and undo", 4.60, 3)
    2000.times do
      play_game_and_clean(game1_moves_ij)
    end
    t.stop
    show_count

    # The idea here is to verify that undoing things is cheaper than throwing it all to GC
    # In a tree exploration strategy the undo should be the only way (otherwise we quickly hog all memory)
    t.start("35 move game, 2000 times new board each time", 4.87, 24)
    2000.times do
      play_game_and_clean(game1_moves_ij,false)
    end
    t.stop
    show_count
  end

  def test_speed2
    tolerance = 1.10
    t = TimeKeeper.new(tolerance)
    t.calibrate(0.7)
    # 9 ++O@@++++
    # 8 +@OO@++@+
    # 7 OOOO@@@++
    # 6 ++OOOOO@@
    # 5 OO@@O@@@@
    # 4 @@@+OOOO@
    # 3 O@@@@@O+O
    # 2 +++@OOO++
    # 1 +++@@O+++
    #   abcdefghi
    game2 = "c3,c6,e7,g3,g7,e2,d2,b4,b3,c7,g5,h4,h5,d8,e8,e5,c4,b5,e3,f2,c5,f6,f7,g6,h6,d7,a4,a5,b6,a3,a6,b7,a4,a7,d9,c9,b8,e6,d5,d6,e9,g4,f5,f4,e1,f1,d1,i5,i6,e4,i4,i3,h8,c8,d3,i5,f3,g2,i4,b5,b4,a5,i5"
    game2_moves_ij = moves_ij(game2)
    # validate the game once
    play_moves(game2_moves_ij)
    final_pos = "++O@@++++,+@OO@++@+,OOOO@@@++,++OOOOO@@,OO@@O@@@@,@@@+OOOO@,O@@@@@O+O,+++@OOO++,+++@@O+++"
    assert_equal(final_pos, @goban.image?);
    
    init_board
    t.start("63 move game, 2000 times and undo", 1.50, 6)
    2000.times do
      play_game_and_clean(game2_moves_ij)
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
      raise "Invalid move: #{move}" if !Stone.valid_move?(@goban, i, j, cur_color)
      Stone.play_at(@goban, i, j, cur_color)
      move_count += 1
      cur_color = (cur_color+1) % 2
    end
    return move_count
  end

  def play_game_and_clean(moves_ij, with_undo=true)
    num_moves = moves_ij.size/2
    $log.debug("About to play a game of #{num_moves} moves") if $debug
    assert_equal(num_moves, play_moves(moves_ij))

    if with_undo then
      num_moves.times { Stone.undo(@goban) }
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
    10.times { Stone.undo(@goban) }
  end
  
end
