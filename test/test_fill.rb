require 'test/unit'

require_relative "../controller"
require_relative "../human_player"
require_relative "../logging"
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
    
    @boan = BoardAnalyser.new(@goban,EMPTY)
  end

  def initialize(x)
    super(x)
    init_board()
  end

  def xtest_fill1
    # 5 +O+++
    # 4 +@+O+
    # 3 +O+@+
    # 2 +@+O+
    # 1 +++@+
    #   abcde
    @goban.load_image("+O+++,+@+O+,+O+@+,+@+O+,+++@+")
    @goban.console_display
    @boan.fill_with_color(3,1,@@x)
    @goban.console_display
    assert_equal("XOXXX,X@XOX,XOX@X,X@XOX,XXX@X", @goban.image?);

    @goban.load_image("+O+++,+@+O+,+O+@+,+@+O+,+++@+")
    @boan.fill_with_color(1,3,@@x)
    assert_equal("XOXXX,X@XOX,XOX@X,X@XOX,XXX@X", @goban.image?);
  end

  def xtest_fill2
    # 5 +++++
    # 4 +OOO+
    # 3 +O+O+
    # 2 +++O+
    # 1 +OOO+
    #   abcde
    @goban.load_image("+++++,+OOO+,+O+O+,+++O+,+OOO+")
    # @goban.console_display
    @boan.fill_with_color(3,3,@@x)
    assert_equal("XXXXX,XOOOX,XOXOX,XXXOX,XOOOX", @goban.image?);

    @goban.load_image("+++++,+OOO+,+O+O+,+++O+,+OOO+")
    @boan.fill_with_color(1,1,@@x)
    assert_equal("XXXXX,XOOOX,XOXOX,XXXOX,XOOOX", @goban.image?);

    @goban.load_image("+++++,+OOO+,+O+O+,+++O+,+OOO+")
    @boan.fill_with_color(5,3,@@x)
    assert_equal("XXXXX,XOOOX,XOXOX,XXXOX,XOOOX", @goban.image?);
  end

  def xtest_fill3
    # 5 +++O+
    # 4 +++OO
    # 3 +O+++
    # 2 ++OO+
    # 1 +O+O+
    #   abcde
    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    @goban.console_display
    @boan.fill_with_color(2,4,@@x)
    assert_equal("XXXO+,XXXOO,XOXXX,XXOOX,XO+OX", @goban.image?);

    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    @boan.fill_with_color(2,2,@@x)
    assert_equal("XXXO+,XXXOO,XOXXX,XXOOX,XO+OX", @goban.image?);

    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    @boan.fill_with_color(3,1,@@x)
    assert_equal("+++O+,+++OO,+O+++,++OO+,+OXO+", @goban.image?);

    @goban.load_image("+++O+,+++OO,+O+++,++OO+,+O+O+")
    @boan.fill_with_color(5,5,@@x)
    assert_equal("+++OX,+++OO,+O+++,++OO+,+O+O+", @goban.image?);
  end

  def test_empty_zones
    init_board(9)
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
    @controller.play_moves(game2)
    final_pos = "++O@@++++,+@OO@++@+,OOOO@@@++,++OOOOO@@,OO@@O@@@@,@@@+OOOO@,O@@@@@O+O,+++@OOO++,+++@@O+++"
    assert_equal(final_pos, @goban.image?);

    @boan.analyse_empty_zones
  end
end
