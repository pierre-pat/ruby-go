require 'test/unit'

require_relative "../logging"
require_relative "../controller"
require_relative "../human_player"
require_relative "../util"

# NB: for debugging think of using @goban.debug_display


class TestFill < Test::Unit::TestCase

  @@x = 0

  def init_board(size=5, num_players=2, handicap=0)
    @controller = Controller.new(size, num_players, handicap)
    @controller.set_player(0, HumanPlayer)
    @controller.set_player(1, HumanPlayer)
    @goban = @controller.goban
    @@x = @goban.char_to_color("X") # we use this color for replacements
  end

  def initialize(x)
    super(x)
    init_board()
  end

  def test_fill1
    # 5 +O+++
    # 4 +@+O+
    # 3 +O+@+
    # 2 +@+O+
    # 1 +++@+
    #   abcde
    @goban.load_image("+O+++,+@+O+,+O+@+,+@+O+,+++@+")
    @goban.console_display
    fill_with_color(@goban,3,1,@@x)
    @goban.console_display
    assert_equal("XOXXX,X@XOX,XOX@X,X@XOX,XXX@X", @goban.image?);

    @goban.load_image("+O+++,+@+O+,+O+@+,+@+O+,+++@+")
    fill_with_color(@goban,1,3,@@x)
    assert_equal("XOXXX,X@XOX,XOX@X,X@XOX,XXX@X", @goban.image?);
  end

  def test_fill2
    # 5 +++++
    # 4 +OOO+
    # 3 +O+O+
    # 2 +++O+
    # 1 +OOO+
    #   abcde
    @goban.load_image("+++++,+OOO+,+O+O+,+++O+,+OOO+")
    # @goban.console_display
    fill_with_color(@goban,3,3,@@x)
    assert_equal("XXXXX,XOOOX,XOXOX,XXXOX,XOOOX", @goban.image?);

    @goban.load_image("+++++,+OOO+,+O+O+,+++O+,+OOO+")
    fill_with_color(@goban,1,1,@@x)
    assert_equal("XXXXX,XOOOX,XOXOX,XXXOX,XOOOX", @goban.image?);

    @goban.load_image("+++++,+OOO+,+O+O+,+++O+,+OOO+")
    fill_with_color(@goban,5,3,@@x)
    assert_equal("XXXXX,XOOOX,XOXOX,XXXOX,XOOOX", @goban.image?);
  end

  def test_fill2
    # 5 +++O+
    # 4 +++OO
    # 3 +O+++
    # 2 ++OO+
    # 1 +O+O+
    #   abcde
    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    @goban.console_display
    fill_with_color(@goban,2,4,@@x)
    assert_equal("XXXO+,XXXOO,XOXXX,XXOOX,XO+OX", @goban.image?);

    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    fill_with_color(@goban,2,2,@@x)
    assert_equal("XXXO+,XXXOO,XOXXX,XXOOX,XO+OX", @goban.image?);

    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    fill_with_color(@goban,3,1,@@x)
    assert_equal("+++O+,+++OO,+O+++,++OO+,+OXO+", @goban.image?);

    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    fill_with_color(@goban,5,5,@@x)
    assert_equal("+++OX,+++OO,+O+++,++OO+,+O+O+", @goban.image?);
  end

end
