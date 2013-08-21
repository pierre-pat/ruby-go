require 'test/unit'

require_relative "../logging"
require_relative "../stone"

# NB: for debugging think of using @goban.console_display


class TestStone < Test::Unit::TestCase

  def init_board()
    @goban = Goban.new(5)
    Group.init(@goban)
  end

  def initialize(x)
    super(x)
    init_board()
  end
  
  def how_many_lives?(i,j)
    s = @goban.stone_at?(i,j)
    lives_before = s.empties.size
    
    # we test the play/undo too
    s = Stone.play_at(@goban,i,j,WHITE)
    lives = s.empties.size
    assert_equal(lives_before, lives)
    Stone.undo(@goban)
    
    lives_after = s.empties.size
    assert_equal(lives_after, lives)
    return lives
  end
  
  # Not very useful anymore for stones
  def test_how_many_lives
    assert_equal(2,how_many_lives?(1,1))
    assert_equal(2,how_many_lives?(@goban.size,@goban.size))
    assert_equal(2,how_many_lives?(1,@goban.size))
    assert_equal(2,how_many_lives?(@goban.size,1))
    assert_equal(4,how_many_lives?(2,2))
    assert_equal(4,how_many_lives?(@goban.size-1,@goban.size-1))
    s=Stone.play_at(@goban, 2, 2, BLACK); # we will try white stones around this one
    g=s.group
    assert_equal(2,how_many_lives?(1,1))
    assert_equal(4,g.lives)
    assert_equal(2,how_many_lives?(1,2))
    assert_equal(4,g.lives) # verify the live count did not change
    assert_equal(2,how_many_lives?(2,1))
    assert_equal(3,how_many_lives?(2,3))
    assert_equal(3,how_many_lives?(3,2))
    assert_equal(4,how_many_lives?(3,3))
  end
  
  def test_play_at
    # single stone
    s = Stone.play_at(@goban, 5, 4, BLACK)
    assert_equal(s, @goban.stone_at?(5,4))
    assert_equal(@goban, s.goban)
    assert_equal(BLACK, s.color)
    assert_equal(5, s.i)
    assert_equal(4, s.j)
  end

  def test_suicide
    # a2 b2 b1 a3 pass c1
    Stone.play_at(@goban, 1, 2, BLACK)
    Stone.play_at(@goban, 2, 2, WHITE)
    Stone.play_at(@goban, 2, 1, BLACK)
    assert_equal(false, Stone.valid_move?(@goban,1,1,WHITE)) # suicide invalid
    Stone.play_at(@goban, 1, 3, WHITE)
    assert_equal(true, Stone.valid_move?(@goban,1,1,WHITE)) # now this would be a kill
    assert_equal(true, Stone.valid_move?(@goban,1,1,BLACK)) # black could a1 too (merge)
    Stone.play_at(@goban, 3, 1, WHITE) # now 2 black stones share a last life
    assert_equal(false, Stone.valid_move?(@goban,1,1,BLACK)) # so this would be a suicide with merge
  end

  def test_ko
    # pass b2 a2 a3 b1 a1
    Stone.play_at(@goban, 2, 2, WHITE)
    Stone.play_at(@goban, 1, 2, BLACK)
    Stone.play_at(@goban, 1, 3, WHITE)
    Stone.play_at(@goban, 2, 1, BLACK)
    Stone.play_at(@goban, 1, 1, WHITE) # kill!
    
    assert_equal(false, Stone.valid_move?(@goban,1,2,BLACK)) # now this is a ko
    Stone.play_at(@goban, 4, 4, BLACK) # play once anywhere else
    Stone.play_at(@goban, 4, 5, WHITE)
    assert_equal(true, Stone.valid_move?(@goban,1,2,BLACK)) # ko can be taken by black
    Stone.play_at(@goban, 1, 2, BLACK) # black takes the ko
    assert_equal(false, Stone.valid_move?(@goban,1,1,WHITE)) # white cannot take the ko
    Stone.play_at(@goban, 5, 5, WHITE) # play once anywhere else
    Stone.play_at(@goban, 5, 4, BLACK)
    assert_equal(true, Stone.valid_move?(@goban,1,1,WHITE)) # ko can be taken back by white
    Stone.play_at(@goban, 1, 1, WHITE) # white takes the ko
    assert_equal(false, Stone.valid_move?(@goban,1,2,BLACK)) # and black cannot take it now
  end

end
