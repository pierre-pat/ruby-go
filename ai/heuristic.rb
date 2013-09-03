
# Base class for all heuristics.
# Anything useful for all of them should be stored as data member here.
class Heuristic

  def initialize(player,consultant=false)
    @player = player
    @color = player.color
    @goban = player.goban
    @size = player.goban.size
    @inf = player.inf
    @enemy_colors = player.enemy_colors
    # For consultant heuristics we reverse the colors
    if consultant
      @color = player.enemy_colors.first
      @enemy_colors = @goban.enemy_colors(@color)
    end
  end

end

