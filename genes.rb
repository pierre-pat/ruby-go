require "yaml"

class Genes

  attr_reader :map
  
  # for limits
  LOW = 0
  HIGH = 1
  
  def initialize
    @map = {}
    @limits = {}
  end
  
  def set_limits(limits)
    @limits = limits
  end
  
  def to_s
    return serialize
  end

  # If limits are given, they will be respected during mutation.
  # The mutated value will remain >=low and <=high.
  # So if you want to remain strictly >0 you have to set a low limit as 0.0001 or alike.
  def get(name, def_value, low_limit = nil, high_limit = nil)
    val = @map[name]
    return val if val
    @map[name] = def_value
    @limits[name] = [low_limit,high_limit] if low_limit or high_limit
    raise "Limits are invalid: #{low_limit} > #{high_limit}" if low_limit and high_limit and low_limit > high_limit
    return def_value
  end

  def serialize
    return YAML::dump(self)
  end
  
  def Genes.unserialize(dump)
    return YAML::load(dump)
  end
  
  def mate(parent2, kid1, kid2, mutation_rate)
    p1 = @map
    p2 = parent2.map
    kid1.set_limits(@limits)
    kid2.set_limits(@limits)
    k1 = kid1.map
    k2 = kid2.map
    k1.clear
    k2.clear
    cross_point = rand(p1.size-1) #TODO double cross
    pos = 0
    p1.each_key do |key|
      if pos <= cross_point
        k1[key] = p1[key]
        k2[key] = p2[key]
      else
        k1[key] = p2[key]
        k2[key] = p1[key]
      end
      k1[key] = mutation1(key,k1[key]) if rand < mutation_rate
      k2[key] = mutation1(key,k2[key]) if rand < mutation_rate  
      pos += 1
    end
  end
  
  # add or remove up to 1
  def mutation1(name,old_val)
    val = old_val + (rand * 2 - 1)
    limits = @limits[name]
    if limits
      low = limits[LOW]
      high = limits[HIGH]
      val = low if low and val < low
      val = high if high and val > high
    end
    return val
  end

end
