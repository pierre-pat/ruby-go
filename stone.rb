require_relative "stone_constants"
require_relative "goban"
require_relative "group"

class Stone

  COLOR_CHARS = "O@X$+" # NB "+" is for empty color == -1
  XY_AROUND = [[0,1],[1,0],[0,-1],[-1,0]] # top, right, bottom, left

  @@color_names = ["black","white","red","blue"] # not constant as this could be user choice
  @@num_colors = 2 # default in real world; I would like to see a game with 3 or 4 one day though :)
  
  attr_reader :goban, :group, :color, :i, :j, :neighbors, :around
  
  def Stone.init(num_colors)
    raise "Max player number is #{@@color_names.size}" if num_colors>@@color_names.size
    @@num_colors = num_colors
  end

  def initialize(goban, i, j, color)
    @goban = goban
    @i = i
    @j = j
    @color = color
    @group = nil
    # @neighbors contains the neighboring stones (empty or not); no need to compute coordinates anymore
    @neighbors = Array.new(4)
    @neighbors.clear
    # @around contains everything around a stone: unique groups (per color) and empty stones
    @around = Array.new(@@num_colors+1) {[]} # +1 for since EMPTY is the last "color"
  end

  # Computes each stone's neighbors (called for each stone after init)
  # NB: Stones next to side have only 3 neighbors, and the corner stones have 2
  def find_neighbors
    XY_AROUND.each do |coord_change|
      stone = goban.stone_at?(@i+coord_change[0], @j+coord_change[1])
      if stone != BORDER then
        @neighbors.push(stone)
        @around[stone.color].push(stone)
      end
    end
  end
  
  def to_s
    "stone#{to_text}:#{as_move}"
  end
  
  def as_move
    "#{Goban.move_as_string(@i,@j)}"
  end
  
  def debug_dump
    s = to_s
    s << " around: "
    EMPTY.upto(@@num_colors-1) do |color|
      s << " #{COLOR_CHARS[color]}["
      @around[color].each do |item|
        s << "#{item.as_move} " if item.is_a?(Stone)
        s << "##{item.ndx} "if item.is_a?(Group)
      end
      s.chop! if @around[color].size>0
      s << "]"
    end
    return s
  end
  
  def to_text
    return COLOR_CHARS[@color]
  end

  def Stone.color_name(color)
    return @@color_names[color]
  end

  def empty?
    return @color == EMPTY
  end

  def Stone.valid_move?(goban, i, j, color)
    # # $log.debug("Stone.valid_move? #{i}, #{j}, color:#{color}") if $debug
    return false if !goban.valid_move?(i,j) # also checks if empty

    stone = goban.stone_at?(i,j)
    return false if stone.move_is_suicide?(color)
    return false if stone.move_is_ko?(color)
    return true
  end

  # Is a move a suicide?
  # not a suicide if 1 free life around
  # or if one enemy group will be killed
  # or if the result of the merge of ally groups will have more than 0 life
  def move_is_suicide?(color)
    return false if @around[EMPTY].size != 0
    
    each_enemy(color) { |enemy| return false if enemy.lives == 1 }
    
    @around[color].each { |ally| return false if ally.lives > 1 }
    
    $log.debug("move #{@i}, #{@j}, color:#{color} would be a suicide") if $debug
    return true
  end
  
  # Is a move a ko?
  # if the move would kill with stone i,j a single stone A (and nothing else!)
  # and the previous move killed with stone A a single stone B in same position i,j
  # then it is a ko
  def move_is_ko?(color)
    group_a,kill_count = nil,0
    each_enemy(color) { |enemy| group_a,kill_count = enemy,kill_count+1 if enemy.lives == 1 }
    return false if kill_count != 1
    return false if group_a.stones.size != 1
    stone_a = group_a.stones.first
    return false if @goban.previous_stone != stone_a
    
    group_b = @goban.killed_groups.last
    return false if group_b.killed_by != stone_a
    return false if group_b.stones.size != 1
    stone_b = group_b.stones.first
    return false if stone_b.i != i or stone_b.j != j

    $log.debug("ko in #{@i}, #{@j}, color:#{color} cannot be played now") if $debug
    return true # a ko!
  end

  def Stone.play_at(goban,i,j,color)
    stone = goban.play_at(i,j,color)
    stone.put_down(color)
    return stone
  end

  def die
    update_around_before_die
    @color = EMPTY
  end
  
  def resuscitate(group)
    @group = group
    @color = group.color
    update_around_on_new
  end

  # Called to undo a single stone (the main undo feature relies on this)  
  def Stone.undo(goban)
    stone = goban.undo()
    return if ! stone
    $log.debug("Stone.undo #{stone}") if $debug
    stone.take_back 
  end
  
  # Iterate through enemy groups
  # This is simply done by going through all colors but EMPTY and the ally (our own color)
  def each_enemy(ally_color)
    0.upto(@@num_colors - 1) do |color|
      next if color == ally_color
      @around[color].each do |enemy|
        raise "Unexpected error (dead or merged enemy)" if enemy.merged_by or enemy.killed_by
        yield enemy
      end
    end
  end

  # Called for each new stone played
  def put_down(color)
    @color = color
    allies = @around[color]
    if allies.size == 0
      @group = Group.new(@goban,self,@around[EMPTY].size)
    else
      @group = allies.first
      @group.connect_stone(self)
      1.upto(allies.size-1) { |a| @group.merge(allies[a],self) }
    end
    update_around_on_new
    each_enemy(color) { |g| g.attacked_by(self) }
  end

  def take_back()
    while @goban.merged_groups.last().merged_by == self do
      ally = @goban.merged_groups.last()
      $log.debug("take_back: about to unmerge "+ally.to_s) if $debug
      @group.unmerge(ally)
    end
    $log.debug("take_back: about to disconnect "+self.to_s) if $debug
    @group.disconnect_stone(self)
    each_enemy(@color) { |g| g.not_attacked_anymore(self) }
    update_around_before_die
    $log.debug("take_back: end; main group: #{@group.debug_dump}") if $debug

    @group = nil
    @color = EMPTY

    while @goban.killed_groups.last().killed_by == self do
      enemy = @goban.killed_groups.last()
      $log.debug("take_back: about to resuscitate "+enemy.to_s) if $debug
      enemy.resuscitate()
    end
  end
  
  def update_around_on_new
    @neighbors.each do |s|
      s.around[EMPTY].delete(self)
      a = s.around[@color]
      a.push(@group) if ! a.find_index(@group)
    end
  end

  def update_around_before_die
    $log.debug("update_around_before_die #{self.debug_dump} removing ##{@group.ndx} from around refs") if $debug
    @neighbors.each do |s|
      s.around[EMPTY].push(self)
      a = s.around[@color]
      if (ndx = a.find_index(@group))
        $log.debug("update_around_before_die: removing ##{@group.ndx} from #{s}") if $debug
        other_neighbor = false
        s.neighbors.each do |stone|
          if stone != self and stone.group == @group
            other_neighbor = true
            break
          end
        end
        a.delete(@group) if ! other_neighbor
        $log.debug("update_around_before_die: not removed since other neighbor exists") if $debug and other_neighbor
      end # if ndx
    end
  end

  def set_group_on_merge(new_group)
    # replace any reference to the old group by the new one
    @neighbors.each do |s|
      a = s.around[@color]
      ndx = a.find_index(@group)
      a[ndx] = new_group if ndx
    end
    @group = new_group
  end

end
