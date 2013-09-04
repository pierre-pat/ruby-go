require 'test/unit'

require_relative "../logging"
require_relative "../controller"
require_relative "../human_player"
require_relative "../ai1_player"

# NB: for debugging think of using @goban.debug_display


class TestAi < Test::Unit::TestCase

  def init_board(size=9, num_players=2, handicap=0)
    c = @controller = Controller.new
    c.new_game(size, num_players, handicap)
    c.set_player(Ai1Player.new(c,BLACK))
    c.set_player(HumanPlayer.new(c,WHITE))
    @goban = c.goban
  end

  def initialize(test_name)
    super(test_name)
    init_board()
  end

  def test_hunter_1
    # h7 is a wrong "good move"; white can escape with h8
    # 9 ++++++++O
    # 8 ++++++++@
    # 7 ++++++++O
    # 6 ++++++++O
    # 5 ++++++++@
    # 4 +++@++++@
    #   abcdefghi
    @controller.load_moves("d4,i7,i8,i6,i5,i9,i4,pass")
    assert_equal("h8", @controller.let_ai_play) # h8 is better than killing in h9
    @controller.load_moves("pass")
    assert_equal("h6", @controller.let_ai_play) # h7 ladder was OK too here but capturing same 2 stones in a ladder
    # the choice between h6 and h7 is decided by smaller differences like distance to corner, etc.
    @controller.load_moves("h7")
    assert_equal("g7", @controller.let_ai_play)
  end

  def test_hunter_2
    # Ladder
    # 9 O+++++++@
    # 8 ++++++++@
    # 7 ++++++++O
    # 6 ++++++++O
    # 5 ++++++++@
    # 4 ++++++++@
    #   abcdefghi
    @controller.load_moves("i9,i7,i8,i6,i5,a9,i4,pass")
    assert_equal("h7", @controller.let_ai_play)
    @controller.load_moves("h6")
    assert_equal("g6", @controller.let_ai_play)
    @controller.load_moves("h5")
    assert_equal("h4", @controller.let_ai_play)
    @controller.load_moves("g5")
    assert_equal("f5", @controller.let_ai_play)
    # @goban.debug_display
  end

  def test_hunter_3
    # Ladder breaker (f4)
    # 9 O+++++++@
    # 8 ++++++++@
    # 7 ++++++++O
    # 6 ++++++++O
    # 5 ++++++++@
    # 4 +++++O++@
    #   abcdefghi
    # AI should prefer to eat 1 stone in a9 since the ladder fails.
    # What is sure is that neither h6 nor h7 works.
    @controller.load_moves("i9,i7,i8,i6,i5,f4,i4,a9")
    move = @controller.let_ai_play
    assert_not_equal("h7", move)
    assert_not_equal("h6", move)
    assert_equal(true, (move == "b9" or move == "a8"))
  end
  
end
