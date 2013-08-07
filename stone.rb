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
    stone.remove if stone != nil
  end

  def Stone.valid_move?(goban, i, j, color)
    return false if !goban.valid_move?(i,j)
    stone = Stone.new(goban,color)
    return stone.check_valid?(i,j)
  end

  def check_valid?(i,j)
    put_down(i,j)
    valid = true
    # no suicide move
    valid = false if @group.lives==0
    # TODO add ko rule here
    remove()
    return valid
  end

  # Returns an array of "coordinate changers" to get positions around any stone
  def Stone.coords_around
    return XY_AROUND
  end

  def look_around()
    allies=[]
    enemies=[]
    lives=0
    # puts "looking around "+@i.to_s+","+@j.to_s
    XY_AROUND.each do |cc|
      stone = @goban.stone_at?(@i+cc[0],@j+cc[1])
      if stone!=nil
        if stone!=EMPTY
          group=stone.group
          if stone.color==@color
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
    lives, allies, enemies = look_around()
    return enemies
  end

  def look_around_for_allies()
    lives, allies, enemies = look_around()
    return allies
  end

  # Counts how many empty positions (life) are around a stone
  # not used but tested
  def look_around_for_lives()
    lives, allies, enemies = look_around()
    return lives
  end
    
  def put_down(i,j)
    @i=i
    @j=j
    @goban.play(i,j,self)
    lives, allies, enemies = look_around()
    if allies.size==0
      @group=Group.new(@goban,self,lives)
    else
      @group=allies[0]
      allies[1,allies.size-1].each { |group| @group.merge(group) }
      @group.connect_stone(self,lives)
    end
    enemies.each { |g| g.attack(self) }
  end

  def remove()
    while @goban.merged_groups.last().merged_with == @group do
      ally = @goban.merged_groups.last()
      @group.unmerge(ally)
    end
    while @goban.killed_groups.last().killed_by == self do
      enemy = @goban.killed_groups.last()
      enemy.resuscitate()
    end
    lives, allies, enemies = look_around()
    enemies.each { |g| g.add_lives(1) }
    @group.disconnect_stone(self,lives) # NB @group == allies[0]
    @goban.undo(self)
  end
end


