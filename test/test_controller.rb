require 'test/unit'

require_relative "../logging"
require_relative "../controller"
require_relative "../human_player"

# TODO: very incomplete test
class TestController < Test::Unit::TestCase

  def init_board(size=5, num_players=2, handicap=0)
    @controller = Controller.new(size, num_players, handicap)
    @controller.set_player(0, HumanPlayer)
    @controller.set_player(1, HumanPlayer)
  end

  def initialize(x)
    super(x)
    init_board()
  end

  # 3 ways to load the same game with handicap...
  def test_handicap
    game6 = "(;FF[4]KM[0.5]SZ[19]HA[6]AB[pd]AB[dp]AB[pp]AB[dd]AB[pj]AB[dj];W[fq])"
    @controller.load_moves(game6)
    img = @controller.goban.image?
    @controller.new_game(19,6)
    @controller.load_moves("f3")
    assert_equal(img, @controller.goban.image?)
    # @controller.goban.console_display
    @controller.new_game(19,0)
    @controller.load_moves("hand:6,f3")
    assert_equal(img, @controller.goban.image?)
  end
  
end