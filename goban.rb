require_relative "stone_constants"

class Goban
  NOTATION_A = "a".ord # notation origin; could be A or a
  
  attr_reader :size, :merged_groups, :killed_groups, :history

  def initialize(size=19)
    @size = size
    @ban = Array.new(size+2)
    (size+2).times do |j|
      if j == 0 or j == size+1
        @ban[j] = Array.new(size+2,BORDER)
      else
        row = Array.new(size+2,EMPTY)
        row[0] = row[size+1] = BORDER
        @ban[j] = row
      end
    end
    @killed_groups = []
    @merged_groups = []
    @history = []
  end
  
  # This display is for debugging and text-only game
  def console_display
    @size.downto(1) do |j|
      printf "%2d ",j.to_s
      1.upto(@size) do |i|
        cell = @ban[j][i]
        if cell == EMPTY then print "+" else print cell.to_text end
      end
      print "\n"
    end
    print "   "
    1.upto(@size) { |i| print(x_label(i)) }
    print "\n"
  end
  
  def x_label(i)
    return (NOTATION_A+i-1).chr
  end

  def valid_move?(i, j)
    return false if i < 1 or i > @size or j < 1 or j > @size
    return false if @ban[j][i] != EMPTY
    return true
  end
  
  def stone_at?(i,j)
    return @ban[j][i]
  end

  def put_stone(i,j,stone)
    @ban[j][i]=stone
  end

  def remove_stone(i,j)
    @ban[j][i]=EMPTY
  end

  # Called by Stone only
  def play(i,j,stone)
    @ban[j][i]=stone
    @history.push(stone)
  end
  
  # Called by Stone only
  def undo(stone)
    raise "Invalid undo" if @history.pop != stone
    @ban[stone.j][stone.i]=EMPTY
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
