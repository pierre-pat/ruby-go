require 'test/unit'

require_relative "../logging"
require_relative "../controller"
require_relative "../human_player"

# NB: for debugging think of using @goban.debug_display


class TestGroup < Test::Unit::TestCase

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

  def test_group_merge
    # check the sentinel
    assert_equal(1, @goban.merged_groups.size)
    assert_equal(-1, @goban.merged_groups.first.color)
    assert_equal(1, @goban.killed_groups.size)
    assert_equal(-1, @goban.killed_groups.first.color)
    
    # single stone
    s = Stone.play_at(@goban, 4, 3, BLACK)
    g = s.group
    assert_equal(@goban, g.goban)
    assert_equal([s], g.stones)
    assert_equal(4, g.lives)
    assert_equal(BLACK, g.color)
    assert_equal(nil, g.merged_by)
    assert_equal(nil, g.killed_by)
    
    # connect a stone to 1 group
    s2 = Stone.play_at(@goban, 4, 2, BLACK)
    assert_equal(g, s.group) # not changed
    assert_equal([s,s2], g.stones)
    assert_equal(6, g.lives)
    assert_equal(nil, g.merged_by)
    assert_equal(s2.group, g) # same group    
    
    # connect 2 groups of 1 stone each
    # (s1 on top, s2 2 rows below, and s3 between them)
    s1 = Stone.play_at(@goban, 2, 5, WHITE)
    g1 = s1.group
    s2 = Stone.play_at(@goban, 2, 3, WHITE)
    g2 = s2.group
    s3 = Stone.play_at(@goban, 2, 4, WHITE)
    g = s3.group
    assert_equal(g1, g) # g1 was kept because on top of stone (comes first)
    assert_equal(g, s1.group)
    assert_equal(g, s2.group)
    assert_equal(7, g.lives)
    assert_equal([s1,s3,s2], g.stones)
    assert_equal(WHITE, g.color)
    assert_equal(nil, g.merged_by)
    assert_equal(g, g2.merged_with) # g2 was merged into g/g1
    assert_equal(s3, g2.merged_by)
    assert_equal([s2], g2.stones) # g2 still knows s2; will be used for reversing
    # check the list in goban
    assert_equal(2, @goban.merged_groups.size)
    assert_equal(g2, @goban.merged_groups.last)
  end

  def test_group_kill
    Stone.play_at(@goban, 1, 5, WHITE) # a5
    s = Stone.play_at(@goban, 1, 4, WHITE) # a4
    g = s.group
    assert_equal(3, g.lives)
    b1 = Stone.play_at(@goban, 2, 4, BLACK) # b4
    Stone.play_at(@goban, 2, 5, BLACK) # b5
    bg=b1.group
    assert_equal(1, g.lives) # g in atari
    assert_equal(3, bg.lives) # black group has 3 lives because of white group on its left
    s=Stone.play_at(@goban, 1, 3, BLACK) # kill!
    assert_equal(5, bg.lives) # black group has now 5 lives
    assert_equal(0, g.lives) # dead
    assert_equal(s, g.killed_by);
    assert_equal(true, @goban.stone_at?(1,5).empty?)
    assert_equal(true, @goban.stone_at?(1,4).empty?)
  end

  # Shape like  O <- the new stone brings only 2 lives
  #            OO    because the one in 3,4 was already owned
  def test_shared_lives_on_connect
    Stone.play_at(@goban, 3, 3, WHITE)
    s=Stone.play_at(@goban, 4, 3, WHITE)
    assert_equal(6, s.group.lives)
    s2=Stone.play_at(@goban, 4, 4, WHITE)
    assert_equal(7, s2.group.lives)
    Stone.undo(@goban)
    assert_equal(6, s.group.lives)
    # @goban.debug_display
  end
  
  # Shape like  OO
  #              O <- the new stone brings 1 life but shared lives 
  #             OO    are not counted anymore in merged group
  def test_shared_lives_on_merge
    Stone.play_at(@goban, 3, 2, WHITE)
    s1=Stone.play_at(@goban, 4, 2, WHITE)
    assert_equal(6, s1.group.lives)
    s2=Stone.play_at(@goban, 3, 4, WHITE)
    assert_equal(4, s2.group.lives)
    Stone.play_at(@goban, 4, 4, WHITE)
    assert_equal(6, s2.group.lives)
    s3=Stone.play_at(@goban, 4, 3, WHITE)
    assert_equal(10, s3.group.lives)
    Stone.undo(@goban)
    assert_equal(6, s1.group.lives)
    assert_equal(6, s2.group.lives)
    Stone.undo(@goban)
    assert_equal(4, s2.group.lives)
    # @goban.debug_display
  end

  # Case of connect + kill at the same time
  # Note the quick way to play a few stones for a test
  # (methods writen before this one used the old, painful style)
  def test_case_1
    @controller.play_moves("a2,a1,b2,b1,c2,d1,pass,e1,c1")
    s = @goban.stone_at?(1,2)
    assert_equal(6, s.group.lives)
  end

  # Other case
  # OOO
  #   O <- new stone
  # OOO
  def test_shared_lives2
    @controller.play_moves("a1,pass,a3,pass,b3,pass,b1,pass,c1,pass,c3,pass,c2")
    s = @goban.stone_at?(1,1)
    assert_equal(8, s.group.lives)
    Stone.undo(@goban)
    assert_equal(4, s.group.lives)
    s2 = @goban.stone_at?(3,1)
    assert_equal(4, s.group.lives)
    # @goban.debug_display
  end

  # Verifies the around values are updated after merge
  # 5 +++++
  # 4 ++@++
  # 3 OOO++
  # 2 @++++
  # 1 +++++
  #   abcde
  def test_merge_and_around
    b1=Stone.play_at(@goban, 1, 3, BLACK)
    bg1=b1.group
    w1=Stone.play_at(@goban, 1, 2, WHITE)
    wg1=w1.group
    assert_equal(2,w1.group.lives)
    assert_equal(2,w1.around[EMPTY].size)
    assert_equal(2,b1.around[EMPTY].size) # unlike the pic above, b3 is not yet played, hence 2
    b2=Stone.play_at(@goban, 3, 3, BLACK)
    bg2=b2.group
    assert_equal(true, bg1 != bg2)
    w2=Stone.play_at(@goban, 3, 4, WHITE)
    1.upto(3) do
      # ++@
      # O+O
      # @++      
      assert_equal(1,b1.around[WHITE].size)
      w2_enemies = w2.around[BLACK]
      assert_equal(1,w2_enemies.size)
      assert_equal(bg2,w2_enemies[0]) # enemy of w2 is bg2
      em=@goban.stone_at?(4,3)
      assert_equal(1,em.around[BLACK].size)
      assert_equal(bg2,em.around[BLACK][0])
      # now merge black groups:
      b3=Stone.play_at(@goban, 2, 3, BLACK)
      assert_equal(true, (b1.group == b2.group) && (b3.group == b1.group))
      assert_equal(true, b1.group == bg1) # and group #1 was used as main (not mandatory but for now it is the case)
      assert_equal(1,w2_enemies.size) # still 1
      assert_equal(bg1,w2_enemies[0]) # but the enemy group should be bg1 now (since bg2 merged with bg1)
      assert_equal(bg1,em.around[BLACK][0]) # same for empty spot next to black group
      assert_equal(1,b1.group.ndx)
      assert_equal(5,b1.group.lives)
      # now get back a bit
      Stone.undo(@goban)
      # not so happy about the asserts below but they test so many things faster...
      assert_equal("{group #1 of 1 black stones [a3], lives:2}",bg1.to_s)
      assert_equal("stoneO:a3 around:  +[a4 b3] O[] @[#2]",b1.debug_dump)
      assert_equal("{group #2 of 1 white stones [a2], lives:2}",w1.group.to_s)      
      assert_equal(true, "stone@:a2 around:  +[b2 a1] O[#1] @[]" == w1.debug_dump ||
                         "stone@:a2 around:  +[a1 b2] O[#1] @[]" == w1.debug_dump)
      assert_equal("{group #3 of 1 black stones [c3], lives:3}",bg2.to_s)
      assert_equal("stoneO:c3 around:  +[d3 c2 b3] O[] @[#4]",b2.debug_dump)
      assert_equal("{group #4 of 1 white stones [c4], lives:3}",w2.group.to_s)
      assert_equal("stone@:c4 around:  +[c5 d4 b4] O[#3] @[]",w2.debug_dump)
      # the one below is nasty: we connect with black, then undo and reconnect with white
      assert_equal(BLACK, @controller.cur_color) # otherwise things are reversed below
      @controller.play_moves("c2,b2,pass,b4,b3,undo,b4,pass,b3")
      # +++++ 5 +++++
      # +@@++ 4 +@@++
      # OOO++ 3 O@O++
      # @@O++ 2 @@O++
      # +++++ 1 +++++
      # abcde   abcde
      assert_equal("{group #1 of 1 black stones [a3], lives:1}",bg1.to_s)
      assert_equal("stoneO:a3 around:  +[a4] O[] @[#2]",b1.debug_dump)
      assert_equal("{group #2 of 5 white stones [a2,b2,b3,c4,b4], lives:6}",wg1.to_s)
      assert_equal("stone@:a2 around:  +[a1] O[#1] @[#2]",w1.debug_dump)
      assert_equal("stone@:b2 around:  +[b1] O[#3] @[#2]",wg1.stones[1].debug_dump)
      assert_equal("stone@:b3 around:  +[] O[#1 #3] @[#2 #2]",wg1.stones[2].debug_dump)
      assert_equal("stone@:c4 around:  +[c5 d4] O[#3] @[#2]",w2.debug_dump)
      assert_equal("stone@:b4 around:  +[b5 a4] O[] @[#2]",wg1.stones[4].debug_dump)
      assert_equal("{group #3 of 2 black stones [c3,c2], lives:3}",bg2.to_s)
      assert_equal("stoneO:c3 around:  +[d3] O[#3] @[#2]",b2.debug_dump)
      assert_equal("stoneO:c2 around:  +[d2 c1] O[#3] @[#2]",bg2.stones[1].debug_dump)
      @controller.play_moves("undo,undo,undo,undo")
      # @goban.debug_display # if any assert shows you might need this to understand what happened...
    end
  end

  # Fixed bug. This was when undo removes a "kill" and restores a stone 
  # ...which attacks (wrongfully) the undone stone
  def test_ko_bug1
    init_board(9,2,5)
    @controller.play_moves("e4,e3,f5,f4,g4,f2,f3,d1,f4,undo,d2,c2,f4,d1,f3,undo,c1,d1,f3,g1,f4,undo,undo,f6")
  end
  
  # This was not a bug actually but the test is nice to have.
  def test_ko_2
    init_board(5,2,0)
    @controller.play_moves("a3,b3,b4,c2,b2,b1,c3,a2,pass,b3")
    # @controller.history.each do |move| puts(move) end
    assert_equal(false, Stone.valid_move?(@goban,2,2,BLACK)) # KO
    @controller.play_moves("e5,d5")
    assert_equal(true, Stone.valid_move?(@goban,2,2,BLACK)) # KO can be taken again
    @controller.play_moves("undo")
    assert_equal(false, Stone.valid_move?(@goban,2,2,BLACK)) # since we are back to the ko time because of undo
  end
  
  # Fixed. Bug was when undo was picking last group by "merged_with" (implemented merged_by)
  def test_bug2
    init_board(9,2,5)
    @controller.play_moves("i1,d3,i3,d4,i5,d5,i7,d6,undo")
  end

  # at this moment this corresponds more or less to the speed test case too
  def test_various1
    init_board(9,2,0)
    @controller.play_moves("pass,b2,a2,a3,b1,a1,d4,d5,a2,e5,e4,a1,undo,undo,undo,undo,undo,undo")
  end

end
