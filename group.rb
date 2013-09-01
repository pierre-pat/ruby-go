require_relative "stone_constants"
# Always require goban instead of stone

# A group keeps the list of its stones, the updated number of "lives" (empty intersections around),
# and whatever status information we need to decide what happens to a group (e.g. when a
# group is killed or merged with another group, etc.).
# Note that most of the work here is to keep this status information up to date.
class Group
  attr_reader :goban, :stones, :lives, :color
  attr_reader :merged_with, :merged_by, :killed_by, :ndx, :eyes, :voids
  attr_writer :merged_with, :merged_by # only used in this file
  
  # Create a new group. Always with a single stone.
  # Do not call this using Group.new but Goban#new_group instead.
  def initialize(goban,stone,lives,ndx)
    @goban = goban
    @stones = [stone]
    @lives = lives
    @color = stone.color
    @merged_with = nil # a group
    @merged_by = nil # a stone
    @killed_by = nil # a stone
    @ndx = ndx # unique index
    @voids = [] # empty zones next to a group (populated and used by analyser)
    @eyes = [] # eyes (i.e. void surrounded by a group; populated and used by analyser)
    @all_enemies = []
    @all_lives = []
    # $log.debug("New group created #{self}") if $debug_group
  end

  def recycle!(stone,lives)
    @stones.clear
    @stones.push(stone)
    @lives = lives
    @color = stone.color
    @merged_with = @merged_by = @killed_by = nil
    @voids.clear
    @eyes.clear
    @all_enemies.clear
    @all_lives.clear
    $log.debug("Use (new) recycled group #{self}") if $debug_group
    return self
  end
  
  def to_s
    s = "{group ##{@ndx} of #{@stones.size}"+
      " #{@goban.color_name(@color)} stones ["
    @stones.each { |stone| s << "#{stone.as_move}," }
    s.chop!
    s << "], lives:#{@lives}"
    s << " MERGED with ##{@merged_with.ndx}" if @merged_with
    s << " KILLED by #{@killed_by.as_move}" if @killed_by
    s << "}"
    return s
  end

  # debug dump does not have more to display now that stones are simpler
  # TODO: remove it unless stones get more state data to display
  def debug_dump
    return to_s
  end
  
  def stones_dump
    return stones.map{|s| s.as_move}.sort.join(",")
  end

  # Adds a void or an eye
  def add_void(void, is_eye = false)
    if is_eye then @eyes.push(void) else @voids.push(void) end
  end
  
  # This also resets the eyes
  def reset_voids
    @voids.clear
    @eyes.clear
  end

  # Builds a list of all lives of the group
  def all_lives
    @all_lives.clear # TODO: try if set is more efficient
    @stones.each do |s|
      s.neighbors.each do |life|
        next if life.color != EMPTY
        @all_lives.push(life) if ! @all_lives.find_index(life)
      end
    end
    return @all_lives
  end

  # Builds a list of all enemies of the group
  def all_enemies
    @all_enemies.clear
    @stones.each do |s|
      s.neighbors.each do |en|
        next if en.color == EMPTY or en.color == @color
        @all_enemies.push(en.group) if ! @all_enemies.find_index(en.group)
      end
    end
    $log.debug("#{self} has #{@all_enemies.size} enemies") if $debug_group
    return @all_enemies    
  end

  # Counts the lives of a stone that are not already in the group
  # (the stone is to be added or removed)
  def lives_added_by_stone(stone)
    lives = 0
    stone.neighbors.each do |life|
      next if life.color != EMPTY
      lives += 1 unless true == life.neighbors.each { |s| break(true) if s.group == self and s != stone }
      # Using any? or detect makes the code clearer but slower :(
      # lives += 1 unless life.neighbors.any? { |s| s.group == self and s != stone }
    end
    $log.debug("#{lives} lives added by #{stone} for group #{self}") if $debug_group
    return lives
  end
  
  # Connect a new stone or a merged stone to this group
  def connect_stone(stone, on_merge = false)
    $log.debug("Connecting #{stone} to group #{self} (on_merge=#{on_merge})") if $debug_group
    @stones.push(stone)
    @lives += lives_added_by_stone(stone)
    @lives -= 1 if !on_merge # minus one since the connection itself removes 1
    raise "Unexpected error (lives<0 on connect)" if @lives<0 # can be 0 if suicide-kill
    $log.debug("Final group: #{self}") if $debug_group
  end
  
  # Disconnect a stone
  # on_merge must be true for merge or unmerge-related call 
  def disconnect_stone(stone, on_merge = false)
    $log.debug("Disconnecting #{stone} from group #{self} (on_merge=#{on_merge})") if $debug_group
    # groups of 1 stone become empty groups (->garbage)
    if @stones.size > 1
      @lives -= lives_added_by_stone(stone)
      @lives += 1 if !on_merge # see comment in connect_stone
      raise "Unexpected error (lives<0 on disconnect)" if @lives<0 # can be 0 if suicide-kill
    else
      @goban.garbage_groups.push(self)
      $log.debug("Group going to recycle bin: #{self}") if $debug_group
    end
    # we always remove them in the reverse order they came
    if @stones.pop != stone then raise "Unexpected error (disconnect order)" end
  end
  
  # When a new stone appears next to this group
  def attacked_by(stone)
    @lives -= 1
    die_from(stone) if @lives <= 0 # also check <0 so we can raise in die_from method
  end

  # When a group of stones reappears because we undo
  # NB: it can never kill anything
  def attacked_by_resuscitated(stone)
    @lives -= 1
    $log.debug("#{self} attacked by resuscitated #{stone}") if $debug_group
    raise "Unexpected error (lives<1 on attack by resucitated)" if @lives<1
  end

  # Stone parameter is just for debug for now
  def not_attacked_anymore(stone)
    @lives += 1
    $log.debug("#{self} not attacked anymore by #{stone}") if $debug_group
  end
  
  # Merges a subgroup with this group
  def merge(subgroup, by_stone)
    raise "Invalid merge" if subgroup.merged_with == self or subgroup == self or @color != subgroup.color
    $log.debug("Merging subgroup:#{subgroup} to main:#{self}") if $debug_group
    subgroup.stones.each do |s| 
      s.set_group_on_merge(self)
      connect_stone(s, true)
    end
    subgroup.merged_with = self
    subgroup.merged_by = by_stone
    @goban.merged_groups.push(subgroup)
    $log.debug("After merge: subgroup:#{subgroup} main:#{self}") if $debug_group
  end

  # Reverse of merge
  def unmerge(subgroup)
    $log.debug("Unmerging subgroup:#{subgroup} from main:#{self}") if $debug_group
    subgroup.stones.reverse_each do |s|
      disconnect_stone(s, true)
      s.set_group_on_merge(subgroup)
    end
    subgroup.merged_by = subgroup.merged_with = nil
    $log.debug("After unmerge: subgroup:#{subgroup} main:#{self}") if $debug_group
  end
  
  # This must be called on the main group (stone.group)
  def unmerge_from(stone)
    while (subgroup = @goban.merged_groups.last).merged_by == stone and subgroup.merged_with == self
      unmerge(@goban.merged_groups.pop)
    end
  end
  
  # Called when the group has no more life left
  def die_from(killer_stone)
    $log.debug("Group dying: #{self}") if $debug_group
    raise "Unexpected error (lives<0)" if @lives < 0
    stones.each do |stone|
      stone.unique_enemies(@color).each { |enemy| enemy.not_attacked_anymore(stone) }
      stone.die
    end
    @killed_by = killer_stone
    @goban.killed_groups.push(self)   
    $log.debug("Group dead: #{self}") if $debug_group
  end
  
  # Called when "undo" operation removes the killer stone of this group
  def resuscitate
    @killed_by = nil
    @lives = 1 # always comes back with a single life
    stones.each do |stone|
      stone.resuscitate_in(self)
      stone.unique_enemies(@color).each { |enemy| enemy.attacked_by_resuscitated(stone) }
    end
  end

  def Group.resuscitate_from(killer_stone,goban)
    while goban.killed_groups.last().killed_by == killer_stone do
      group = goban.killed_groups.pop
      $log.debug("taking back #{killer_stone} so we resuscitate #{group.debug_dump}") if $debug_group
      group.resuscitate()
    end
  end

  # Returns prisoners grouped by color of dead stones  
  def Group.prisoners?(goban)
    prisoners = Array.new(goban.num_colors,0)
    1.upto(goban.killed_groups.size-1) do |i|
      g = goban.killed_groups[i]
      prisoners[g.color] += g.stones.size
    end
    return prisoners
  end
  
end
