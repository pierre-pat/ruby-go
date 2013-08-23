require_relative "stone_constants"
require_relative "stone"
require_relative "group"

# Stores what we have on the board (namely, the stones and the empty spaces).
# Giving coordinates, a Goban can return an existing stone.
# It also remembers the list of stones played and can share this info for undo feature.
# This class does not care about more than that.
# See Stone and Group classes for the layer above this.
class Goban
  NOTATION_A = "a".ord # notation origin; could be A or a

  COLOR_CHARS = "@OX$+" # NB "+" is for empty color == -1
  @@color_names = ["black","white","red","blue"] # not constant as this could be user choice
  @@num_colors = 2 # default in real world; I would like to see a game with 3 or 4 one day though :)
  
  attr_reader :size, :merged_groups, :killed_groups, :garbage_groups

  def initialize(size=19, num_colors=2)
    @size = size
    raise "Max player number is #{@@color_names.size}" if num_colors>@@color_names.size
    @@num_colors = num_colors
    # We had a few discussions about the added "border" below.
    # Idea is to avoid to have to check i,j against size in many places.
    # Also in case of bug, e.g. for @ban[5][-1] Ruby returns you @ban[5][@ban.size] (looping back)
    # so having a real item (BORDER) on the way is easier to detect as a bug.
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
    @@sentinel = Group.new(self, Stone.new(self,-1,-1,-1), -1, 0)
    @killed_groups = [@@sentinel] # so that we can always do @killed_groups.last.color, etc.
    @merged_groups = [@@sentinel]
    @garbage_groups = []
    @num_groups = 0
    @history = []
  end
  
  # Allocate a new group or recycles one from garbage list.
  # For efficiency, call this one, do not call the regular Group.new method.
  def new_group(stone,lives)
    group = garbage_groups.pop
    if group
      return group.recycle!(stone,lives)
    else
      @num_groups += 1
      return Group.new(self,stone,lives,@num_groups)
    end
  end

  # Returns the "character" used to represent a stone in text style
  def stone_to_text(color)
    return COLOR_CHARS[color]
  end
  def color_to_char(color)
    return COLOR_CHARS[color]
  end
  
  def char_to_color(char)
    return EMPTY if char == COLOR_CHARS[EMPTY] # we have to because EMPTY is -1, not COLOR_CHARS.size
    return COLOR_CHARS.index(char)
  end

  # Returns the name of the color/player (e.g. "black")
  def color_name(color)
    return @@color_names[color]
  end

  # For debugging and text-only; receives a block of code and calls it for each non empty stone
  # The block should return a string representation of the stone (or whatever related to it)
  # This method returns the concatenated string showing a board
  def _to_console(double_char=false)
    s = ""
    @size.downto(1) do |j|
      s << "#{'%2d' % j} "
      1.upto(@size) { |i|
        if @ban[j][i].color == EMPTY
          s << (double_char ? "[]" : COLOR_CHARS[EMPTY])
        else
          s << yield(@ban[j][i])
        end
      }
      s << "\n"
    end
    s << "   "
    if double_char then 1.upto(@size) { |i| s << " #{x_label(i)}" }
    else 1.upto(@size) { |i| s << x_label(i) } end
    s << "\n"
  end

  # For debugging only
  def debug_display
    puts "Board:"
    print _to_console { |s| stone_to_text(s.color) }
    puts "Groups:"
    groups={}
    double_char = (@num_groups >= 10)
    print _to_console(double_char) { |s|
      groups[s.group.ndx] = s.group
      (double_char ? "#{'%02d' % s.group.ndx}" : "#{s.group.ndx}")
    }
    puts "Full info on groups and stones:"
    1.upto(@num_groups) {|ndx| puts groups[ndx].debug_dump if groups[ndx]}
  end

  # This display is for debugging and text-only game
  def console_display
    print _to_console { |s| stone_to_text(s.color) }
  end

  # Watch out our images are upside-down on purpose (to help copy paste from screen)
  # So last row (j==size) comes first in image
  def image?
    s = ""
    @size.downto(1) do |j|
      1.upto(@size) { |i| s << stone_to_text(@ban[j][i].color) }
      s << ","
    end
    return s.chop!
  end
  
  # Watch out our images are upside-down on purpose (to help copy paste from screen)
  # So last row (j==size) comes first in image
  def load_image(image)
    rows = image.split(/\"|,/)
    raise "Invalid image: #{rows.size} rows instead of #{@size}" if rows.size != @size
    @size.downto(1) do |j|
      row = rows[size-j]
      raise "Invalid image: row #{row}" if row.length != @size
      1.upto(@size) do |i|
        color = char_to_color(row[i-1])
        @ban[j][i].mark_a_spot!(color)
      end
    end
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

  # Wil be used for various evaluations (currently for filling a zone)
  # color should not be a player's color nor EMPTY unless we do not plan to 
  # continue the game on this goban (or we plan to restore everything we marked)
  def mark_a_spot!(i,j,color) # TODO refactor me
    @ban[j][i].mark_a_spot!(color)
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
    return "#{(col+NOTATION_A-1).chr}#{row}"
  end
  
  # Converts a numeric X coordinate in a letter (e.g 3->c)
  def x_label(i)
    return (i+NOTATION_A-1).chr
  end

end
