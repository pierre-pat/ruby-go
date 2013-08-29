require_relative "samples"


class Heuristic
  def Heuristic.all_heuristics
    return [Spacer,AvoidBorders,Killer,Savior]
  end
end
