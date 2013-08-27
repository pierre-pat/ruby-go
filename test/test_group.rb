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
    @controller.load_moves("a2,a1,b2,b1,c2,d1,pass,e1,c1")
    s = @goban.stone_at?(1,2)
    assert_equal(6, s.group.lives)
  end

  # Other case
  # OOO
  #   O <- new stone
  # OOO
  def test_shared_lives2
    @controller.load_moves("a1,pass,a3,pass,b3,pass,b1,pass,c1,pass,c3,pass,c2")
    s = @goban.stone_at?(1,1)
    assert_equal(8, s.group.lives)
    Stone.undo(@goban)
    assert_equal(4, s.group.lives)
    @goban.stone_at?(3,1)
    assert_equal(4, s.group.lives)
    # @goban.debug_display
  end

  def check_group(g, ndx,num_stones,color,stones,lives)
    assert_equal(ndx,g.ndx)
    assert_equal(num_stones,g.stones.size)
    assert_equal(color,g.color)
    assert_equal(lives,g.lives)
    assert_equal(stones,g.stones_dump)
  end

  def check_stone(s,color,move,around)
    assert_equal(color, s.color)
    assert_equal(move, s.as_move)
    assert_equal(around, s.lives_dump)
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
    assert_equal(2,w1.group.lives)
    b2=Stone.play_at(@goban, 3, 3, BLACK)
    bg2=b2.group
    assert_equal(true, bg1 != bg2)
    w2=Stone.play_at(@goban, 3, 4, WHITE)
    3.times do
      # ++@
      # O+O
      # @++      
      @goban.stone_at?(4,3)
      # now merge black groups:
      b3=Stone.play_at(@goban, 2, 3, BLACK)
      assert_equal(true, (b1.group == b2.group) && (b3.group == b1.group))
      assert_equal(3, b1.group.ndx) # and group #3 was used as main (not mandatory but for now it is the case)
      assert_equal(5,b1.group.lives)
      # now get back a bit
      Stone.undo(@goban)
      
      check_group(bg1, 1,1,0,"a3",2) # group #1 of 1 black stones [a3], lives:2
      check_stone(b1, 0,"a3","a4,b3") # stoneO:a3 around:  +[a4 b3]
      check_group(w1.group, 2,1,1,"a2",2) # group #2 of 1 white stones [a2], lives:2
      check_stone(w1, 1,"a2","a1,b2") # stone@:a2 around:  +[a1 b2]
      check_group(bg2, 3,1,0,"c3",3) # group #3 of 1 black stones [c3], lives:3
      check_stone(b2, 0,"c3","b3,c2,d3") # stoneO:c3 around:  +[d3 c2 b3]
      check_group(w2.group, 4,1,1,"c4",3) # group #4 of 1 white stones [c4], lives:3 
      check_stone(w2, 1,"c4","b4,c5,d4") # stone@:c4 around:  +[c5 d4 b4]
      # the one below is nasty: we connect with black, then undo and reconnect with white
      assert_equal(BLACK, @controller.cur_color) # otherwise things are reversed below
      @controller.load_moves("c2,b2,pass,b4,b3,undo,b4,pass,b3")
      # +++++ 5 +++++
      # +@@++ 4 +@@++
      # OOO++ 3 O@O++
      # @@O++ 2 @@O++
      # +++++ 1 +++++
      # abcde   abcde
      check_group(bg1, 1,1,0,"a3",1) # group #1 of 1 black stones [a3], lives:1
      check_stone(b1, 0,"a3","a4") # stoneO:a3 around:  +[a4]
      wgm = w1.group # white group after merge
      check_group(wgm, 4,5,1,"a2,b2,b3,b4,c4",6)
      check_stone(w1, 1,"a2","a1") # stone@:a2 around:  +[a1]
      check_stone(@goban.stone_at?(2,2), 1,"b2","b1") # stone@:b2 around:  +[b1]
      check_stone(@goban.stone_at?(2,3), 1,"b3","") # stone@:b3 around:  +[]
      check_stone(@goban.stone_at?(2,4), 1,"b4","a4,b5") # stone@:b4 around:  +[b5 a4]
      check_stone(w2, 1,"c4","c5,d4") # stone@:c4 around:  +[c5 d4]
      check_group(bg2, 3,2,0,"c2,c3",3); # group #3 of 2 black stones [c3,c2], lives:3
      check_stone(b2, 0,"c3","d3") # stoneO:c3 around:  +[d3]
      check_stone(@goban.stone_at?(3,2), 0,"c2","c1,d2") # stoneO:c2 around:  +[d2 c1]
      @controller.load_moves("undo,undo,undo,undo")
      # @goban.debug_display # if any assert shows you might need this to understand what happened...
    end
  end
  
  # Fixed bug. This was when undo removes a "kill" and restores a stone 
  # ...which attacks (wrongfully) the undone stone
  def test_ko_bug1
    init_board(9,2,5)
    @controller.load_moves("e4,e3,f5,f4,g4,f2,f3,d1,f4,undo,d2,c2,f4,d1,f3,undo,c1,d1,f3,g1,f4,undo,undo,f6")
  end

  # At the same time a stone kills (with 0 lives left) and connects to existing surrounded group,
  # killing actually the enemy around. We had wrong raise showing since at a point the group
  # we connect to has 0 lives. We simply made the raise test accept 0 lives as legit.
  def test_kamikaze_kill_while_connect
    init_board(5,2,0)
    @controller.load_moves("a1,a3,b3,a4,b2,b1,b4,pass,a5,a2,a1,a2,undo,undo")
  end
  
  # This was not a bug actually but the test is nice to have.
  def test_ko_2
    init_board(5,2,0)
    @controller.load_moves("a3,b3,b4,c2,b2,b1,c3,a2,pass,b3")
    # @controller.history.each do |move| puts(move) end
    assert_equal(false, Stone.valid_move?(@goban,2,2,BLACK)) # KO
    @controller.load_moves("e5,d5")
    assert_equal(true, Stone.valid_move?(@goban,2,2,BLACK)) # KO can be taken again
    @controller.load_moves("undo")
    assert_equal(false, Stone.valid_move?(@goban,2,2,BLACK)) # since we are back to the ko time because of undo
  end
  
  # Fixed. Bug was when undo was picking last group by "merged_with" (implemented merged_by)
  def test_bug2
    init_board(9,2,5)
    @controller.load_moves("i1,d3,i3,d4,i5,d5,i7,d6,undo")
  end

  # At this moment this corresponds more or less to the speed test case too
  def test_various1
    init_board(9,2,0)
    @controller.load_moves("pass,b2,a2,a3,b1,a1,d4,d5,a2,e5,e4,a1,undo,undo,undo,undo,undo,undo")
  end
  
  # This test for fixing bug we had if a group is merged then killed and then another stone played
  # on same spot as the merging stone, then we undo... We used to only look at merging stone to undo a merge.
  # We simply added a check that the merged group is also the same.
  def test_another_undo
    init_board(5,2,0)
    @controller.load_moves("e1,e2,c1,d1,d2,e1,e3,e1,undo,undo,undo,undo")
  end
  
  # Makes sure that die & resuscite actions behave well
  def test_and_again_undo
    init_board(5,2,0)
    @controller.load_moves("a1,b1,c3")
    ws = @goban.stone_at?(1,1)
    wg = ws.group
    @controller.load_moves("a2")
    assert_equal(0,wg.lives)
    assert_equal(EMPTY,ws.color)
    assert_equal(true,ws.group == nil)
    @controller.load_moves("undo")
    assert_equal(1,wg.lives)
    assert_equal(BLACK,ws.color)
    @controller.load_moves("c3,a2") # and kill again the same
    assert_equal(0,wg.lives)
    assert_equal(EMPTY,ws.color)
    assert_equal(true,ws.group == nil)
  end

end
