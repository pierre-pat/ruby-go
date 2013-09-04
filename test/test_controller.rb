require 'test/unit'

require_relative "../logging"
require_relative "../controller"
require_relative "../human_player"

# TODO: very incomplete test
class TestController < Test::Unit::TestCase

  def init_board(size=5, num_players=2, handicap=0)
    c = @controller = Controller.new
    c.new_game(size, num_players, handicap)
    c.set_player(HumanPlayer.new(c,BLACK))
    c.set_player(HumanPlayer.new(c,WHITE))
    @goban = c.goban
  end

  def initialize(test_name)
    super(test_name)
    init_board()
  end

  # 3 ways to load the same game with handicap...
  def test_handicap
    game6 = "(;FF[4]KM[0.5]SZ[19]HA[6]AB[pd]AB[dp]AB[pp]AB[dd]AB[pj]AB[dj];W[fq])"
    @controller.load_moves(game6)
    img = @goban.image?
    @controller.new_game(19,2,6)
    @controller.load_moves("f3")
    assert_equal(img, @goban.image?)
    # @controller.goban.console_display
    @controller.new_game(19,2,0)
    @controller.load_moves("hand:6,f3")
    assert_equal(img, @goban.image?)
  end
  
end