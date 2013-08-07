require_relative "stone_constants"

class Group
  attr_reader :goban, :stones, :lives, :color, :merged_with, :killed_by, :sentinel
  attr_writer :merged_with
  
  def Group.init(goban)
    @@sentinel = Group.new(goban, Stone.new(goban,-1), -1)
    goban.merged_groups.push(@@sentinel)
    goban.killed_groups.push(@@sentinel)
  end
  
  def initialize(goban,stone,lives)
    @goban = goban
    @stones = [stone]
    @lives = lives
    @color=stone.color
    @merged_with = nil
    @killed_by = nil
  end
  
  def to_s
    "("+(@merged_with?"MERGED ":"")+(@killed_by?"KILLED ":"")+
    Stone::color_name(@color)+" group of "+@stones.size.to_s+
    " stones, first "+@stones.first.to_s+")"
  end

  def connect_stone(stone, lives)
    @lives += lives-1
    @stones.push(stone)
  end
  
  def disconnect_stone(stone, lives)
    @lives -= lives-1
    raise "Unexpected error" if @stones.pop != stone
  end
  
  def attack(stone)
    @lives -= 1
    die(stone) if @lives == 0
  end
  
  def merge(subgroup)
    @lives += subgroup.lives-1
    @stones.concat(subgroup.stones)
    subgroup.stones.each { |s| s.set_group(self) }
    subgroup.merged_with = self
    @goban.merged_groups.push(subgroup)
  end

  def unmerge(subgroup)
    @lives -= subgroup.lives-1
    subgroup.stones.each do |s|
      @stones.delete(s)
      s.set_group(subgroup)
    end
    subgroup.merged_with = nil
    @goban.merged_groups.pop
  end
  
  def die(killed_by)
    stones.each do |stone|
      @goban.remove_stone(stone.i, stone.j)
      enemies = stone.look_around_for_enemies()
      enemies.each { |enemy| enemy.add_lives(1) }
    end
    @killed_by = killed_by
    @goban.killed_groups.push(self)   
  end
  
  def resuscitate()
    stones.each do |stone|
      @goban.put_stone(stone.i, stone.j, stone)
      enemies = stone.look_around_for_enemies()
      enemies.each { |enemy| enemy.add_lives(-1) }
    end
    @killed_by = nil
    @goban.killed_groups.pop
  end

  def add_lives(lives)
    @lives += lives
  end

end
