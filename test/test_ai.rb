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
    c.set_player(Ai1Player.new(c,WHITE))
    @goban = c.goban
  end

  def initialize(test_name)
    super(test_name)
    init_board()
  end

  def test_cornering
    # 9 ++++++++O
    # 8 ++++++++@
    # 7 +++@+++++
    # 6 +++++++++
    # 5 ++O++++++
    # 4 +++++++++
    #   abcdefghi
    @controller.load_moves("i8,i9,d7,c5")
    # @goban.debug_display
    assert_equal("h9", @controller.let_ai_play) # FIXME: h8 is better than killing in h9
  end

  def test_issue_hunter
    # 5 +++++++++
    # 4 +@@@@O+++
    # 3 ++O@O@O++
    # 2 ++O@O@+++
    # 1 +++OO++++
    #   abcdefghi
    @controller.load_moves("d4,e2,d2,c3,d3,c2,b4,d1,c4,f4,f3,e3,e4,g3,f2,e1")
    # @goban.debug_display
    assert_equal("c1", @controller.let_ai_play) # FIXME: should NOT be c1
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
    @controller.load_moves("d4,i7,i8,i6,i5,i9,i4,pass,h8,pass")
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

  def test_dead_group
    # 9 +@++@@@@O
    # 8 +@@@@@@OO
    # 7 @@+@+@@O+
    # 6 +@+@++@O+
    # 5 +@+@@+@O+
    # 4 @@@+++@OO
    # 3 @OO@@@@O+
    # 2 OO+OOO@OO
    # 1 ++O@@@@O+
    #   abcdefghi
    # Interesting here: SW corner group O (white) is dead. Both sides should see it and play accordingly.
    @controller.load_moves("d6,f4,e5,f6,g5,f5,g7,h6,g6,e7,f7,e6,g3,h4,g4,h5,d8,c7,d7,f8,e8,d4,d5,e4,f9,g9,e9,c9,g8,c8,h9,d9,e3,f2,f3,h7,c4,c5,d3,c6,b5,h8,b7,a6,b6,a4,b9,a5,b8,b3,b4,c3,c2,e2,a7,d2,a3,b2,g1,c1,g2,h2,i3,h3,f1,i2,e1,i4,d1,a2,a4,h1,c8,i8,f8,i9,g9")
    move = @controller.let_ai_play
    assert_equal("pass", move)
    move = @controller.let_ai_play
    assert_equal("c2", move) # optim here would be @ realizing this is not necessary
    move = @controller.let_ai_play
    assert_equal("pass", move)
    move = @controller.let_ai_play
    assert_equal("b1", move) # same remark
    move = @controller.let_ai_play
    assert_equal("pass", move)
    move = @controller.let_ai_play
    assert_equal("a1", move) # and same again
    move = @controller.let_ai_play
    assert_equal("pass", move)
    move = @controller.let_ai_play
    assert_equal("a2", move) # TODO: this one really should not be played
  end
  
  def test_border_defense
    init_board(7)
    # 7 +++++++
    # 6 +++@@@+
    # 5 @++@OO+
    # 4 O@@@O@+
    # 3 OOOO+O+
    # 2 ++O@O++
    # 1 +++++++
    #   abcdefg
    # Issue: after W:a3 we expect B:b5 or b6 but AI does not see attack in b5; 
    @controller.load_moves("d4,c2,d2,e5,d6,e4,d5,d3,e3,c3,f4,f5,f6,f3,e6,e2,b4,b3,c4,a4,a5,a3")
    move = @controller.let_ai_play
    assert_equal("g5", move) # FIXME current move should be b6 here
  end

  def test_border_attack_and_invasion
    init_board(7)
    # 7 +++++++
    # 6 +++@@@@
    # 5 @*+@OO@
    # 4 O@@@O+O
    # 3 OOOO+O+
    # 2 ++O+O++
    # 1 +++O+++
    #   abcdefg
    # AI should see attack in b5 with territory invasion
    @controller.load_moves("d4,c2,d2,e5,d6,e4,d5,d3,e3,c3,f4,f5,f6,f3,e6,e2,b4,b3,c4,a4,a5,a3,g6,d1,g5,g4,pass")
    move = @controller.let_ai_play
    assert_equal("b5", move)
  end

  def test_border_attack_and_invasion2
    init_board(7)
    # 7 +++++++
    # 6 +++@@@@
    # 5 @*+@OO+
    # 4 O@@@O@+
    # 3 OOOO+O+
    # 2 ++O@O++
    # 1 +++++++
    #   abcdefg
    # AI should see attack in b5 with territory invasion
    @controller.load_moves("d4,c2,d2,e5,d6,e4,d5,d3,e3,c3,f4,f5,f6,f3,e6,e2,b4,b3,c4,a4,a5,a3,g6")
    move = @controller.let_ai_play
    assert_equal("g4", move) # FIXME current move should be b5 here
  end

  def test_border_closing
    init_board(7)
    # 7 +++++++
    # 6 +@+@@@@
    # 5 @++@OO+
    # 4 O@@@O@+
    # 3 OOOO+O+
    # 2 ++O+O++
    # 1 +++O+++
    #   abcdefg
    # AI should see f4 is dead inside white territory if g5 is played (non trivial)
    @controller.load_moves("d4,c2,d2,e5,d6,e4,d5,d3,e3,c3,f4,f5,f6,f3,e6,e2,b4,b3,c4,a4,a5,a3,b6,d1,g6")
    move = @controller.let_ai_play
    assert_equal("g4", move) # FIXME current move should be g5 here
  end

  def test_killing_saves_nearby_group_in_atari
    init_board(7)
    # 7 +++++++
    # 6 +@+@@@+
    # 5 @++@OO@
    # 4 O@@@O@+
    # 3 OOOO+O+
    # 2 ++O+O++
    # 1 +++O+++
    #   abcdefg
    @controller.load_moves("d4,c2,d2,e5,d6,e4,d5,d3,e3,c3,f4,f5,f6,f3,e6,e2,b4,b3,c4,a4,a5,a3,b6,d1,g5")
    move = @controller.let_ai_play
    assert_equal("e3", move) # FIXME current move should be g4 here 
    # (TODO: executioner needs to see that killing f4 also saves 3 white stones)
    # once this is fixed we can verify the standard ending moves below are played.
    # move = @controller.let_ai_play
    # assert_equal("g6", move)
    # move = @controller.let_ai_play
    # assert_equal("pass", move)
    # move = @controller.let_ai_play
    # assert_equal("pass", move)
  end
  
  def test_snapback
    init_board(5)
    # 5 O@+O+
    # 4 O@*@@
    # 3 OO@++
    # 2 ++@++
    # 1 +++++
    #   abcde
    # c4 expected for white, then if c5, c4 again (snapback)
    @controller.load_moves("b5,a5,b4,a4,c3,b3,c2,a3,d4,d5,e4")
    move = @controller.let_ai_play
    assert_equal("c4", move)
    @controller.play_one_move("c5")
    move = @controller.let_ai_play
    assert_equal("c4", move)
  end

  def test_snapback2
    init_board(5)
    # 5 O@+OO
    # 4 O@+@+
    # 3 OO@@+
    # 2 +@@++
    # 1 +++++
    #   abcde
    @controller.load_moves("b5,a5,b4,a4,c3,b3,c2,a3,d4,d5,d3,e5,b2")
    # @goban.debug_display
    move = @controller.let_ai_play
    assert_equal("c5", move) # FIXME should be c4
  end
  
  def test_snapback3
    init_board(5)
    # 5 O@+OO
    # 4 O@O@+
    # 3 OO@@+
    # 2 ++@++
    # 1 ++@++
    #   abcde
    @controller.load_moves("b5,a5,b4,a4,c3,b3,c2,a3,d4,d5,d3,e5,c1,c4")
    # @goban.debug_display
    move = @controller.let_ai_play
    assert_equal("c5", move) # FIXME should NOT be c5
  end

  def test_snapback4
    init_board(5)
    # 5 O@@OO
    # 4 O@+@+
    # 3 OO@@+
    # 2 ++@++
    # 1 ++@++
    #   abcde
    @controller.load_moves("b5,a5,b4,a4,c3,b3,c2,a3,d4,d5,d3,e5,c1,c4,c5")
    move = @controller.let_ai_play
    assert_equal("c4", move)
    move = @controller.let_ai_play
    assert_equal("c5", move) # FIXME should NOT be c5 (hunter sees it as good)
    # @goban.debug_display
  end

end
