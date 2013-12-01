require 'test/unit'

require_relative "../breeder"


class TestBreeder < Test::Unit::TestCase

  def initialize(test_name)
    super(test_name)
  end

  def test_bw_balance
    num_games = 200
    size = 9
    tolerance = 0.15 # 0.10=>10% (+ or -); the more games you play the lower tolerance you can set (but it takes more time...)
    b = Breeder.new(size)
    num_wins = b.bw_balance_check(num_games,size)
    assert_in_epsilon(num_wins,num_games/2,tolerance)
  end

end
