
# Base class for all heuristics.
# Anything useful for all of them should be stored as data member here.
class Heuristic

  def initialize(player)
    @player = player
    @color = player.color
    @goban = player.goban
    @size = player.goban.size
    @inf = player.inf
    @enemy_colors = player.enemy_colors
  end

  def switch_side
    new_color = @enemy_colors.first
    @enemy_colors = @goban.enemy_colors(@color)
    @color = new_color
  end

end

