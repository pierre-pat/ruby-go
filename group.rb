require_relative "stone_constants"

# A group keeps the list of its stones, the updated number of "lives" (empty intersections around),
# and whatever status information we need to decide what happens to a group (e.g. when a
# group is killed or merged with another group, etc.).
# Note that most of the work here is to keep this status information up to date.
class Group
  attr_reader :goban, :stones, :lives, :color
  attr_reader :merged_with, :merged_by, :killed_by, :sentinel, :ndx
  attr_writer :merged_with, :merged_by # only used in this file
  
  def Group.init(goban)
    @@ndx = 0
    @@sentinel = Group.new(goban, Stone.new(goban,-1,-1,-1), -1)
    goban.merged_groups.push(@@sentinel)
    goban.killed_groups.push(@@sentinel)
  end
  
  # Create a new group. Always with a single stone.
  def initialize(goban,stone,lives)
    @goban = goban
    @stones = [stone]
    @lives = lives
    @color=stone.color
    @merged_with = nil # a group
    @merged_by = nil # a stone
    @killed_by = nil # a stone
    @ndx = @@ndx # unique index (more for debug)
    @@ndx += 1
  end
  
  # Returns the total number of group created (mostly for debug)
  def Group.count
    @@ndx
  end
  
  def to_s
    s = "{group ##{@ndx} of #{@stones.size}"+
      " #{Stone::color_name(@color)} stones ["
    @stones.each { |stone| s << "#{stone.as_move}," }
    s.chop!
    s << "], lives:#{@lives}"
    s << " MERGED with ##{@merged_with.ndx}" if @merged_with
    s << " KILLED by #{@killed_by.as_move}" if @killed_by
    s << "}"
    return s
  end

  def debug_dump
    s = to_s
    s << "\n"
    stones.each { |stone| s << "    #{stone.debug_dump}\n" }
    return s
  end
  
  def stones_dump
    return stones.map{|s| s.as_move}.sort.join(",")
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
    $log.debug("#{lives} lives added by #{stone} for group #{self}") if $debug
    return lives
  end
  
  # Connect a new stone or a merged stone to this group
  def connect_stone(stone, on_merge = false)
    $log.debug("Connecting #{stone} to group #{self} (on_merge=#{on_merge})") if $debug
    @stones.push(stone)
    @lives += lives_added_by_stone(stone)
    @lives -= 1 if !on_merge # minus one since the connection itself removes 1
    raise "Unexpected error (lives<0 on connect)" if @lives<0 # can be 0 if suicide-kill
    $log.debug("Final group: #{self}") if $debug
  end
  
  # Disconnect a stone 
  def disconnect_stone(stone, on_merge = false)
    $log.debug("Disconnecting #{stone} from group #{self} (on_merge=#{on_merge})") if $debug
    # remark: for groups of a single stone we simply let the empty group go (garbage)
    if @stones.size > 1
      @lives -= lives_added_by_stone(stone)
      @lives += 1 if !on_merge # see comment in connect_stone
      raise "Unexpected error (lives<0 on disconnect)" if @lives<0 # can be 0 if suicide-kill
    end
    # we always remove them in the reverse order they came
    if @stones.pop != stone then raise "Unexpected error (disconnect order)" end
  end
  
  # When a new stone appears next to this group
  def attacked_by(stone)
    @lives -= 1
    die_from(stone) if @lives == 0
  end

  # When a group of stones reappears because we undo
  # NB: it can never kill anything
  def attacked_by_resuscitated(stone)
    $log.debug("#{self} attacked by resuscitated #{stone}") if $debug
    @lives -= 1
    raise "Unexpected error (lives<1 on attack by resucitated)" if @lives<1
  end

  # Stone parameter is just for debug for now
  def not_attacked_anymore(stone)
    @lives += 1
    $log.debug("#{self} not attacked anymore by #{stone}") if $debug
  end
  
  # Merges a subgroup with this group
  def merge(subgroup, by_stone)
    raise "Invalid merge" if subgroup.merged_with == self or subgroup == self or @color != subgroup.color
    $log.debug("Merging subgroup:#{subgroup} to main:#{self}") if $debug
    subgroup.stones.each do |s| 
      s.set_group_on_merge(self)
      connect_stone(s, true)
    end
    subgroup.merged_with = self
    subgroup.merged_by = by_stone
    @goban.merged_groups.push(subgroup)
    $log.debug("After merge: subgroup:#{subgroup} main:#{self}") if $debug
  end

  # Reverse of merge
  def unmerge(subgroup)
    $log.debug("Unmerging subgroup:#{subgroup} from main:#{self}") if $debug
    subgroup.stones.reverse_each do |s|
      disconnect_stone(s, true)
      s.set_group_on_merge(subgroup)
    end
    subgroup.merged_by = subgroup.merged_with = nil
    $log.debug("After unmerge: subgroup:#{subgroup} main:#{self}") if $debug
  end
  
  # This must be called on the main group (stone.group)
  def unmerge_from(stone)
    while (subgroup = @goban.merged_groups.last).merged_by == stone and subgroup.merged_with == self
      unmerge(@goban.merged_groups.pop)
    end
  end
  
  # Called when the group has no more life left
  def die_from(killer_stone)
    $log.debug("Group dying: #{self}") if $debug
    stones.each do |stone|
      stone.unique_enemies(@color).each { |enemy| enemy.not_attacked_anymore(stone) }
      stone.die
    end
    @killed_by = killer_stone
    @goban.killed_groups.push(self)   
    $log.debug("Group dead: #{self}") if $debug
  end
  
  # Called when "undo" operation removes the killer stone of this group
  def resuscitate
    $log.debug("Group resuscitating: #{self.debug_dump}") if $debug
    stones.each do |stone|
      stone.resuscitate_in(self)
      stone.unique_enemies(@color).each do |enemy|
        $log.debug("nearby enemy: #{enemy.debug_dump}") if $debug
        enemy.attacked_by_resuscitated(stone) 
      end
    end
    @killed_by = nil
  end

  def Group.resuscitate_from(killer_stone,goban)
    while goban.killed_groups.last().killed_by == killer_stone do
      group = goban.killed_groups.pop
      $log.debug("take_back: about to resuscitate "+group.to_s) if $debug
      group.resuscitate()
    end
  end
  
end
