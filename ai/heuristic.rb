
# Base class for all heuristics.
# Anything useful for all of them should be stored as data member here.
class Heuristic

  def initialize(player)
    @color = player.color
    @goban = player.goban
    @size = player.goban.size
    @inf = player.inf
    @enemy_colors = player.enemy_colors
  end

end

