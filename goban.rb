require_relative "stone_constants"

# Stores what we have on the board (namely, the stones and the empty spaces).
# Giving coordinates, a Goban can return an existing stone.
# It also remembers the list of stones played and can share this info for undo feature.
# This class does not care about more than that.
# See Stone and Group classes for the layer above this.
class Goban
  NOTATION_A = "a".ord # notation origin; could be A or a
  
  attr_reader :size, :merged_groups, :killed_groups

  def initialize(size=19)
    @size = size
    @ban = Array.new(size+2)
    @ban[0] = Array.new(size+2,BORDER)
    @ban[size+1] = Array.new(size+2,BORDER)
    1.upto(size) do |j|
      row = Array.new(size+2)
      row[0] = row[size+1] = BORDER
      1.upto(size) { |i| row[i]=Stone.new(self,i,j,EMPTY) }
      @ban[j] = row
    end
    1.upto(size) do |j|
      1.upto(size) do |i|
        @ban[j][i].find_neighbors
      end
    end
    @killed_groups = []
    @merged_groups = []
    @history = []
  end
  
  # For debugging and text-only; receives a block of code and calls it for each stone
  def _to_console
    @size.downto(1) do |j|
      printf "%2d ",j.to_s
      1.upto(@size) do |i|
        cell = @ban[j][i]
        yield cell
      end
      print "\n"
    end
    print "   "
    1.upto(@size) { |i| print(x_label(i)) }
    print "\n"
  end

  # For debugging only
  def debug_display
    puts "Board:"
    _to_console {|s| print(s.empty? ? "+" : s.to_text) }
    puts "Groups:"
    groups={}
    _to_console do |s|
      print(s.empty? ? "+" : s.group.ndx); 
      groups[s.group.ndx]=s.group if !s.empty?
    end
    puts "Full info on groups and stones:"
    1.upto(Group.count) {|ndx| puts groups[ndx].debug_dump if groups[ndx]}
  end

  # This display is for debugging and text-only game
  def console_display
    _to_console {|s| if s.empty? then print "+" else print s.to_text end}
  end
  
  # Converts a numeric X coordinate in a letter (e.g 3->c)
  def x_label(i)
    return (NOTATION_A+i-1).chr
  end

  # Basic validation only: coordinates and checks the intersection is empty
  # See Stone class for evolved version of this (calling this one)
  def valid_move?(i, j)
    return false if i < 1 or i > @size or j < 1 or j > @size
    return false if ! @ban[j][i].empty?
    return true
  end
  
  def stone_at?(i,j)
    return @ban[j][i]
  end
  
  def color?(i,j)
    stone = @ban[j][i]
    return stone.color if stone
    return BORDER
  end
  
  # Plays a stone and stores it in history
  # Actually we simply return the existing stone and the caller will update it
  def play_at(i,j,color)
    stone=@ban[j][i]
    @history.push(stone)
    return stone
  end
  
  # Removes the last stone played from the board
  # Actually we simply return the existing stone and the caller will update it
  def undo()
    return @history.pop
  end
  
  def previous_stone
    return @history.last
  end
  
  # Parses a move like "c12" into 3,12
  def Goban.parse_move(move)
    return move[0].ord-NOTATION_A+1, move[1,2].to_i
  end
  
  # Builds a string representation of a move (3,12->"c12")  
  def Goban.move_as_string(col, row)
    return (col+NOTATION_A-1).chr+row.to_s;
  end
end
