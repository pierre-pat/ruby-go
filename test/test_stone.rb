require_relative "../stone"
require_relative "../goban"

class TestStone
  def initialize
    @goban = nil
  end
  
  def TestStone.run
    t = TestStone.new
    t.test_how_many_lives
    t.test_play_at
    t.test_group_merge
    t.test_group_kill
    puts "All tests completed"
  end
  
  def assert_eql(expected,val)
    raise "failed assertion; expected:\n"+expected.to_s+
      "\n = = = = = = = = and instead we got:\n"+val.to_s if val!=expected
  end

  def init(size)
    @goban = Goban.new(5)
    Group.init(@goban)
  end
  
  def how_many_lives?(i,j)
    s = Stone.play_at(@goban,i,j,WHITE)
    lives = s.look_around_for_lives()
    Stone.undo(@goban)
    return lives
  end
  
  def test_how_many_lives
    init(5)
    assert_eql(2,how_many_lives?(1,1))
    assert_eql(2,how_many_lives?(@goban.size,@goban.size))
    assert_eql(2,how_many_lives?(1,@goban.size))
    assert_eql(2,how_many_lives?(@goban.size,1))
    assert_eql(4,how_many_lives?(2,2))
    assert_eql(4,how_many_lives?(@goban.size-1,@goban.size-1))
  
    s=Stone.play_at(@goban, 2, 2, BLACK); # we will try white stones around this one
    g=s.group
    assert_eql(2,how_many_lives?(1,1))
    assert_eql(4,g.lives)
    assert_eql(2,how_many_lives?(1,2))
    assert_eql(4,g.lives) # verify the live count did not change
    assert_eql(2,how_many_lives?(2,1))
    assert_eql(3,how_many_lives?(2,3))
    assert_eql(3,how_many_lives?(3,2))
    assert_eql(4,how_many_lives?(3,3))
  end
  
  def test_play_at
    init(5)
    # single stone
    s = Stone.play_at(@goban, 5, 4, BLACK)
    assert_eql(s, @goban.stone_at?(5,4))
    assert_eql(@goban, s.goban)
    assert_eql(BLACK, s.color)
    assert_eql(5, s.i)
    assert_eql(4, s.j)
  end

  def test_group_merge
    init(5)
    # check the sentinel
    assert_eql(1, @goban.merged_groups.size)
    assert_eql(-1, @goban.merged_groups.first.color)
    assert_eql(1, @goban.killed_groups.size)
    assert_eql(-1, @goban.killed_groups.first.color)
    
    # single stone
    s = Stone.play_at(@goban, 4, 3, BLACK)
    g = s.group
    assert_eql(@goban, g.goban)
    assert_eql([s], g.stones)
    assert_eql(4, g.lives)
    assert_eql(BLACK, g.color)
    assert_eql(nil, g.merged_with)
    assert_eql(nil, g.killed_by)
    
    # connect a stone to 1 group
    s2 = Stone.play_at(@goban, 4, 2, BLACK)
    assert_eql(g, s.group) # not changed
    assert_eql([s,s2], g.stones) # merged
    assert_eql(6, g.lives)
    assert_eql(nil, g.merged_with)
    assert_eql(s2.group, g) # same group    
    
    # connect 2 groups of 1 stone each
    # (s1 on top, s2 2 rows below, and s3 between them)
    s1 = Stone.play_at(@goban, 2, 5, WHITE)
    g1 = s1.group
    s2 = Stone.play_at(@goban, 2, 3, WHITE)
    g2 = s2.group
    s3 = Stone.play_at(@goban, 2, 4, WHITE)
    g = s3.group
    assert_eql(g1, g) # g1 was kept because on top of stone (comes first)
    assert_eql(g, s1.group)
    assert_eql(g, s2.group)
    assert_eql(7, g.lives)
    assert_eql([s1,s2,s3], g.stones)
    assert_eql(WHITE, g.color)
    assert_eql(nil, g.merged_with)
    assert_eql(g, g2.merged_with) # g2 was merged into g/g1
    assert_eql([s2], g2.stones) # g2 still knows s2; will be used for reversing
    # check the list in goban
    assert_eql(2, @goban.merged_groups.size)
    assert_eql(g2, @goban.merged_groups.last)
  end

  def test_group_kill
    init(5)
    Stone.play_at(@goban, 1, 5, WHITE)
    s = Stone.play_at(@goban, 1, 4, WHITE)
    g = s.group
    assert_eql(3, g.lives)
    b1=Stone.play_at(@goban, 2, 4, BLACK)
    Stone.play_at(@goban, 2, 5, BLACK)
    bg=b1.group
    assert_eql(1, g.lives) # g in atari
    assert_eql(3, bg.lives) # black group has 3 lives because of white group on its left
    s=Stone.play_at(@goban, 1, 3, BLACK) # kill!
    assert_eql(5, bg.lives) # black group has now 5 lives
    assert_eql(0, g.lives) # dead
    assert_eql(s, g.killed_by);
    assert_eql(EMPTY, @goban.stone_at?(1,5))
    assert_eql(EMPTY, @goban.stone_at?(1,4))
  end

end

TestStone.run