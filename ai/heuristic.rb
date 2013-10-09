
# Base class for all heuristics.
# Anything useful for all of them should be stored as data member here.
class Heuristic

  attr_reader :negative

  def initialize(player,consultant=false)
    @player = player
    @consultant = consultant
    @negative = false
    @goban = player.goban
    @size = player.goban.size
    @inf = player.inf
  end
  
  def init_color
    @color = @player.color
    @enemy_colors = @player.enemy_colors
    # For consultant heuristics we reverse the colors
    if @consultant
      @color = @player.enemy_colors.first
      @enemy_colors = @goban.enemy_colors(@color)
    end
  end
  
  def set_as_negative
    @negative = true
  end
  
  def get_gene(name, def_val, low_limit=nil, high_limit=nil)
    @player.genes.get("#{self.class.name}-#{name}",def_val,low_limit,high_limit)
  end

end

