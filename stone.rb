require_relative "stone_constants"
require_relative "goban"
require_relative "group"

class Stone

  COLOR_CHARS = "O@X$"
  XY_AROUND = [[0,1],[1,0],[0,-1],[-1,0]] # top, right, bottom, left

  @@color_names=["black","white","red","blue"] # not constant as this could be user choice
  
  attr_reader :goban, :group, :color, :i, :j
  
  def Stone.init(num_colors)
    raise "Max player number is "+@@color_names.size.to_s if num_colors>@@color_names.size
  end

  def initialize(goban, color)
    @goban = goban
    @color = color
    @group = nil
  end
  
  def to_s
    "stone:"+i.to_s+","+j.to_s
  end
  
  def set_group(group)
    @group = group
  end

  def to_text
    return COLOR_CHARS[@color]
  end

  def Stone.color_name(color)
    return @@color_names[color]
  end

  def Stone.play_at(goban,i,j,color)
    stone = Stone.new(goban, color)
    stone.put_down(i,j)
    return stone
  end
  
  def Stone.undo(goban)
    stone = goban.history.last()
    stone.take_back if stone != nil
  end

  def Stone.valid_move?(goban, i, j, color)
    return false if !goban.valid_move?(i,j)

    lives, allies, enemies = Stone.look_around(goban,i,j,color)
    return false if Stone.move_is_suicide?(lives,allies,enemies)
    return false if Stone.move_is_ko?(goban,i,j,enemies)
    return true
  end

  # Is a move a suicide?
  # not a suicide if 1 free life around
  # or if one enemy group will be killed
  # or if the result of the merge of ally groups will have more than 0 life
  def Stone.move_is_suicide?(lives, allies, enemies)
    return false if lives != 0
    enemies.each { |enemy| return false if enemy.lives == 1 }
    
    total = 0
    allies.each { |ally| total += ally.lives-1 }
    return false if total>=1
    
    return true # a suicide!
  end
  
  # Is a move a ko?
  # if the move would kill with stone i,j a single stone A (and nothing else!)
  # and the previous move killed with stone A a single stone B in same position i,j
  # then it is a ko
  def Stone.move_is_ko?(goban, i, j, enemies)
    group_a,kill_count = nil,0
    enemies.each { |enemy| group_a,kill_count = enemy,kill_count+1 if enemy.lives == 1 }
    return false if kill_count != 1
    return false if group_a.stones.size != 1
    stone_a = group_a.stones[0]
    return false if goban.history.last != stone_a
    
    group_b = goban.killed_groups.last
    return false if group_b.killed_by != stone_a
    return false if group_b.stones.size != 1
    stone_b = group_b.stones[0]
    return false if stone_b.i != i or stone_b.j != j
    return true # a ko!
  end

  # Returns an array of "coordinate changers" to get positions around any stone
  def Stone.coords_around
    return XY_AROUND
  end

  def Stone.look_around(goban,i,j,color)
    allies=[]
    enemies=[]
    lives=0
    # puts "looking around "+i.to_s+","+j.to_s
    XY_AROUND.each do |cc|
      stone = goban.stone_at?(i+cc[0], j+cc[1])
      if stone!=nil
        if stone!=EMPTY
          group=stone.group
          if stone.color == color
            allies.push(group) if allies.find_index(group)==nil
          else
            enemies.push(group) if enemies.find_index(group)==nil
          end
        else 
          lives+=1
        end
      end
    end
    return lives, allies, enemies
  end

  def look_around_for_enemies()
    lives, allies, enemies = Stone.look_around(@goban,@i,@j,@color)
    return enemies
  end

  # Counts how many empty positions (life) are around a stone
  # not used but tested
  def look_around_for_lives()
    lives, allies, enemies = Stone.look_around(@goban,@i,@j,@color)
    return lives
  end
    
  def put_down(i,j)
    @i=i
    @j=j
    @goban.play(i,j,self)
    lives, allies, enemies = Stone.look_around(@goban,@i,@j,@color)
    if allies.size==0
      @group=Group.new(@goban,self,lives)
    else
      @group=allies[0]
      allies[1,allies.size-1].each { |group| @group.merge(group) }
      @group.connect_stone(self,lives)
    end
    enemies.each { |g| g.attack(self) }
  end

  def take_back()
    while @goban.merged_groups.last().merged_with == @group do
      ally = @goban.merged_groups.last()
      @group.unmerge(ally)
    end
    while @goban.killed_groups.last().killed_by == self do
      enemy = @goban.killed_groups.last()
      enemy.resuscitate()
    end
    lives, allies, enemies = Stone.look_around(@goban,@i,@j,@color)
    enemies.each { |g| g.add_lives(1) }
    @group.disconnect_stone(self,lives) # NB @group == allies[0]
    @goban.undo(self)
  end
end


