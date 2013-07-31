class Goban
  EMPTY =- 1
  BORDER = nil
  NOTATION_A = "a".ord #notation origin; could be A or a
  
  attr_reader :size

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
  end
  
  def display
    @size.downto(1) do |j|
      printf "%2d ",j.to_s
      @ban[j].each do |cell|
        if cell == EMPTY
          print "+"
        elsif cell != BORDER
          cell.display
        end
      end
      print "\n"
    end
    print "   "
    @size.times { |i| print((NOTATION_A+i).chr) }
    print "\n"
  end
  
  def display_score
    display
    puts "Game ended. Score: ..."
  end

  def valid_move?(i, j, color)
    return false if i < 1 or i > @size or j < 1 or j > @size
    return false if @ban[j][i] != EMPTY
    #TODO add go rules here: no suicide and ko
    return true
  end
  
  #called only by the controller
  def play(move, color)
    i, j = Goban.parse_move(move)
    raise "Invalid move generated:"+move if !valid_move?(i, j, color)
    @ban[j][i] = Stone.new(color)
  end

  #Parses a move like "c12" into 3,12
  def Goban.parse_move(move)
    return move[0].ord-NOTATION_A+1, move[1,2].to_i
  end
  
  #Builds a string representation of a move (3,12->"c12")  
  def Goban.move_as_string(col, row)
    return (col+NOTATION_A-1).chr+row.to_s;
  end
end
