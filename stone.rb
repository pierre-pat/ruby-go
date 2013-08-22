require_relative "stone_constants"
# Always require goban first
# require_relative "goban" # for Goban.move_as_string
# require_relative "group" # for Group.resuscitate_from

# A "stone" stores everything we want to keep track of regarding an intersection on the board.
# By extension, an empty intersection is also a stone, with a color attribute equals to EMPTY.
# This class is also the entry point for moves in general, so it has methods to play or undo,
# and verify if a planned move is authorized.
class Stone

  COLOR_CHARS = "O@X$+" # NB "+" is for empty color == -1
  XY_AROUND = [[0,1],[1,0],[0,-1],[-1,0]] # top, right, bottom, left

  @@color_names = ["black","white","red","blue"] # not constant as this could be user choice
  @@num_colors = 2 # default in real world; I would like to see a game with 3 or 4 one day though :)
  
  attr_reader :goban, :group, :color, :i, :j, :neighbors
  
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
    # @allies and @enemies are used as buffers for corresonding methods (unique_allies, unique_enemies etc.)
    @allies = Array.new(4)
    @enemies = Array.new(4)
  end

  # Computes each stone's neighbors (called for each stone after init)
  # NB: Stones next to side have only 3 neighbors, and the corner stones have 2
  def find_neighbors
    @neighbors.clear
    XY_AROUND.each do |coord_change|
      stone = goban.stone_at?(@i+coord_change[0], @j+coord_change[1])
      @neighbors.push(stone) if stone != BORDER
    end
  end
  
  def to_s
    "stone#{to_text}:#{as_move}"
  end
  
  # Returns "c3" for a stone in 3,3
  def as_move
    "#{Goban.move_as_string(@i,@j)}"
  end
  
  def debug_dump
    to_s # we could add more info
  end

  # As of now this is used for debug only  
  def empties
    @neighbors.select { |s| s.color == EMPTY }
  end

  # Returns a string with the list of lives, sorted (debug only)
  def lives_dump
    return empties.map{|s| s.as_move}.sort.join(",")
  end
  
  # Returns the "character" used to represent a stone in text style
  def to_text
    return COLOR_CHARS[@color]
  end
  
  def Stone.char_to_color(char)
    return EMPTY if char == COLOR_CHARS[EMPTY] # we have to because EMPTY is -1, not COLOR_CHARS.size
    return COLOR_CHARS.index(char)
  end

  # Returns the name of the color/player for this stone (e.g. "black")
  def Stone.color_name(color)
    return @@color_names[color]
  end

  def empty?
    return @color == EMPTY
  end

  def Stone.valid_move?(goban, i, j, color)
    # Remark: no log here because of the noise created with web server mode
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
    @neighbors.each do |s|
      return false if s.color == EMPTY
      if s.color != color
        return false if s.group.lives == 1
      else
        return false if s.group.lives > 1
      end
    end
    $log.debug("move #{@i}, #{@j}, color:#{color} would be a suicide") if $debug
    return true
  end
  
  # Is a move a ko?
  # if the move would kill with stone i,j a single stone A (and nothing else!)
  # and the previous move killed with stone A a single stone B in same position i,j
  # then it is a ko
  def move_is_ko?(color)
    # Must kill a single group
    group_a = nil
    each_enemy(color) { |enemy| next if enemy.lives != 1; return false if group_a; group_a = enemy }
    return false if ! group_a
    # This killed group must be a single stone A
    return false if group_a.stones.size != 1
    stone_a = group_a.stones.first
    # Stone A was played just now
    return false if @goban.previous_stone != stone_a
    
    # Stone B was killed by A in same position we are looking at
    group_b = @goban.killed_groups.last
    return false if group_b.killed_by != stone_a
    return false if group_b.stones.size != 1
    stone_b = group_b.stones.first
    return false if stone_b.i != @i or stone_b.j != @j

    $log.debug("ko in #{@i}, #{@j}, color:#{color} cannot be played now") if $debug
    return true
  end

  def Stone.play_at(goban,i,j,color)
    stone = goban.play_at(i,j,color)
    stone.put_down(color)
    return stone
  end
  
  # Wil be used for various evaluations (currently for filling a zone)
  # color should not be a player's color nor EMPTY unless we do not plan to 
  # continue the game on this goban (or we plan to restore everything we marked)
  def mark_a_spot!(color) # TODO refactor me
    $log.debug("marking in #{@i},#{@j} with color #{color} (old value: #{@color})") if $debug
    @color = color
  end

  def die
    # update_around_before_die
    @color = EMPTY
    @group = nil # at this moment we can omit this but cleaner
  end
  
  def resuscitate_in(group)
    @group = group
    @color = group.color
    # update_around_on_new
  end

  # Called to undo a single stone (the main undo feature relies on this)  
  def Stone.undo(goban)
    stone = goban.undo()
    return if ! stone
    $log.debug("Stone.undo #{stone}") if $debug
    stone.take_back 
  end
  
  # Iterate through enemy groups and calls the given block
  # (same group appears more than once if it faces the stone 2 times or more)
  # Example: +@@+
  #          +@O+ <- for stone O, the @ group will be selected 2 times
  #          ++++
  def each_enemy(ally_color)
    @neighbors.each { |s| yield s.group if s.color != EMPTY and s.color != ally_color }
  end

  def unique_enemies(ally_color)
    @enemies.clear
    @neighbors.each do |s|
      @enemies.push(s.group) if s.color != EMPTY and s.color != ally_color and ! @enemies.find_index(s.group)
    end
    return @enemies
  end

  # Iterate through our groups and calls the given block
  # (same group appears more than once if it faces the stone 2 times or more)
  # See also each_enemy
  def each_ally(ally_color)
    @neighbors.each { |s| yield s.group if s.color == ally_color }
  end

  def unique_allies(color)
    @allies.clear
    @neighbors.each do |s|
      @allies.push(s.group) if s.color == color and ! @allies.find_index(s.group)
    end
    return @allies
  end

  # Called for each new stone played
  def put_down(color)
    @color = color
    allies = unique_allies(color) # note we would not need unique if group#merge ignores dupes
    if allies.size == 0
      lives = 0
      @neighbors.each { |s| lives += 1 if s.color == EMPTY }
      @group = @goban.new_group(self,lives)
    else
      @group = allies.first
      @group.connect_stone(self)
      1.upto(allies.size-1) { |a| @group.merge(allies[a],self) }
    end
    # update_around_on_new
    unique_enemies(color).each { |g| g.attacked_by(self) }
  end

  def take_back()
    $log.debug("take_back: #{to_s} from group #{@group}") if $debug
    @group.unmerge_from(self)
    @group.disconnect_stone(self)
    unique_enemies(@color).each { |g| g.not_attacked_anymore(self) }

    # update_around_before_die
    log_group = @group if $debug
    @group = nil
    @color = EMPTY

    Group.resuscitate_from(self,@goban)
    $log.debug("take_back: end; main group: #{log_group.debug_dump}") if $debug
  end
  
  def set_group_on_merge(new_group)
    @group = new_group
  end

  # Not used anymore but could become handy again later
  # def update_around_on_new
  #   $log.debug("update_around_on_new #{self.debug_dump}") if $debug
  # end

  # Not used anymore but could become handy again later
  # def update_around_before_die
  #   $log.debug("update_around_before_die #{self.debug_dump}") if $debug
  # end

end
