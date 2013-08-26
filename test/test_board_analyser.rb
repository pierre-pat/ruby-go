require 'test/unit'

require_relative "../controller"
require_relative "../human_player"
require_relative "../logging"
require_relative "../board_analyser"

# NB: for debugging think of using analyser.debug_dump


class TestBoardAnalyser < Test::Unit::TestCase

  def init_board(size=5, num_players=2, handicap=0)
    @controller = Controller.new(size, num_players, handicap)
    @controller.set_player(0, HumanPlayer)
    @controller.set_player(1, HumanPlayer)
    @goban = @controller.goban
    
    @boan = BoardAnalyser.new(@goban)
  end

  def initialize(x)
    super(x)
    init_board()
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
    prisoners = Group.prisoners?(@goban)
    assert_equal([4,5], prisoners)

    @boan.count_score
    # we do not test private method anymore
    # tmp_zones = "FFO@@EEEE,F@OO@EE@E,OOOO@@@EE,DDOOOOO@@,OO@@O@@@@,@@@COOOO@,O@@@@@OBO,AAA@OOOBB,AAA@@OBBB"
    # assert_equal(tmp_zones, @boan.image?)
    final_zones = "::O@@----,:@OO@--@-,OOOO@@@--,::OOOOO@@,OO@@O@@@@,@@@?OOOO@,O@@@@@O:O,---@OOO::,---@@O:::"
    @boan.debug_dump if $debug
    assert_equal([16,12], @boan.scores)
    assert_equal([4+1,5+1], @boan.prisoners)
    
    @boan.restore
    assert_equal(final_pos, @goban.image?);
  end
end
