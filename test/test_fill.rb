require 'test/unit'

require_relative "../logging"
require_relative "../controller"
require_relative "../human_player"
require_relative "../util"

# NB: for debugging think of using @goban.debug_display


class TestFill < Test::Unit::TestCase

  def init_board(size=5, num_players=2, handicap=0)
    @controller = Controller.new(size, num_players, handicap)
    @controller.set_player(0, HumanPlayer)
    @controller.set_player(1, HumanPlayer)
    @goban = @controller.goban
  end

  def initialize(x)
    super(x)
    init_board()
  end

  def test_fill1
    # 5 +@+++
    # 4 +O+@+
    # 3 +@+O+
    # 2 +O+@+
    # 1 +++O+
    #   abcde
    @goban.load_image("+@+++,+O+@+,+@+O+,+O+@+,+++O+")
    @goban.console_display
    fill_with_color(@goban,3,1,Stone.char_to_color("X"))
    @goban.console_display
    assert_equal("X@XXX,XOX@X,X@XOX,XOX@X,XXXOX", @goban.image?);

    @goban.load_image("+@+++,+O+@+,+@+O+,+O+@+,+++O+")
    fill_with_color(@goban,1,3,Stone.char_to_color("X"))
    assert_equal("X@XXX,XOX@X,X@XOX,XOX@X,XXXOX", @goban.image?);
  end

  def test_fill2
    # 5 +++++
    # 4 +@@@+
    # 3 +@+@+
    # 2 +++@+
    # 1 +@@@+
    #   abcde
    @goban.load_image("+++++,+@@@+,+@+@+,+++@+,+@@@+")
    # @goban.console_display
    fill_with_color(@goban,3,3,Stone.char_to_color("X"))
    assert_equal("XXXXX,X@@@X,X@X@X,XXX@X,X@@@X", @goban.image?);

    @goban.load_image("+++++,+@@@+,+@+@+,+++@+,+@@@+")
    fill_with_color(@goban,1,1,Stone.char_to_color("X"))
    assert_equal("XXXXX,X@@@X,X@X@X,XXX@X,X@@@X", @goban.image?);

    @goban.load_image("+++++,+@@@+,+@+@+,+++@+,+@@@+")
    fill_with_color(@goban,5,3,Stone.char_to_color("X"))
    assert_equal("XXXXX,X@@@X,X@X@X,XXX@X,X@@@X", @goban.image?);
  end

  def test_fill2
    # 5 +++@+
    # 4 +++@@
    # 3 +@+++
    # 2 ++@@+
    # 1 +@+@+
    #   abcde
    @goban.load_image("+++@+,+++@@,+@+++,++@@+,+@+@+")
    @goban.console_display
    fill_with_color(@goban,2,4,Stone.char_to_color("X"))
    assert_equal("XXX@+,XXX@@,X@XXX,XX@@X,X@+@X", @goban.image?);

    @goban.load_image("+++@+,+++@@,+@+++,++@@+,+@+@+")
    fill_with_color(@goban,2,2,Stone.char_to_color("X"))
    assert_equal("XXX@+,XXX@@,X@XXX,XX@@X,X@+@X", @goban.image?);

    @goban.load_image("+++@+,+++@@,+@+++,++@@+,+@+@+")
    fill_with_color(@goban,3,1,Stone.char_to_color("X"))
    assert_equal("+++@+,+++@@,+@+++,++@@+,+@X@+", @goban.image?);

    @goban.load_image("+++@+,+++@@,+@+++,++@@+,+@+@+")
    fill_with_color(@goban,5,5,Stone.char_to_color("X"))
    assert_equal("+++@X,+++@@,+@+++,++@@+,+@+@+", @goban.image?);
  end

end
