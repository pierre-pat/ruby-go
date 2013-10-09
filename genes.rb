require "yaml"

class Genes

  SMALL_MUTATION_AMOUNT = 0.05 # e.g. 0.05 -> plus or minus 5%

  attr_reader :map
  
  # for limits
  LOW = 0
  HIGH = 1
  
  def initialize(map = {}, limits = {})
    @map = map
    @limits = limits
  end
  
  def clone
    return Genes.new(@map.clone, @limits.clone)
  end
  
  def set_limits(limits)
    @limits = limits
  end
  
  def to_s
    s = ""
    @map.each_key { |k| s << "#{k}:#{'%.02f' % @map[k]}, " }
    return s.chomp!(", ")
  end
  
  # Returns a distance between 2 sets of genes
  def distance(gene2)
    dist = 0.0
    @map.each_key do |k|
      m = @map[k]
      n = gene2.map[k]
      # first handle sign differences
      if (n < 0) != (m < 0)
        if n<0 then m -= n; n = 0
        else n -= m; m = 0 end
      else
        m = m.abs; n = n.abs
      end
      # then separate 0 values
      if n == 0.0
        d = ( m > 1.0 ? 1.0 : m )
      elsif m == 0.0
        d = ( n > 1.0 ? 1.0 : n )
      else
        # finally we can do a ratio
        d = 1.0 - ( n >= m ? m / n : n / m )
      end
      dist += d
      # puts "Distance for #{k} between #{'%.02f' % @map[k]} and #{'%.02f' % gene2.map[k]}: #{d}"
    end
    # puts "Total distance: #{'%.02f' % dist}"
    return dist
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
  
  # mutation_rate: 0.05 for 5% mutation on each gene
  # wide_mutation_rate: 0.20 for 20% chances to pick any value in limit range
  # if wide mutation is not picked, a value near to the old value is picked
  def mate(parent2, kid1, kid2, mutation_rate, wide_mutation_rate)
    p1 = @map
    p2 = parent2.map
    kid1.set_limits(@limits)
    kid2.set_limits(@limits)
    k1 = kid1.map
    k2 = kid2.map
    cross_point_2 = rand(p1.size)
    cross_point = rand(cross_point_2)
    pos = 0
    p1.each_key do |key|
      if pos < cross_point or pos > cross_point_2
        k1[key] = p1[key]
        k2[key] = p2[key]
      else
        k1[key] = p2[key]
        k2[key] = p1[key]
      end
      k1[key] = mutation1(key,k1[key],wide_mutation_rate) if rand < mutation_rate
      k2[key] = mutation1(key,k2[key],wide_mutation_rate) if rand < mutation_rate  
      pos += 1
    end
  end
  
  def mutation1(name,old_val,wide_mutation_rate)
    limits = @limits[name]
    if limits
      low = limits[LOW]
      high = limits[HIGH]
      if rand < wide_mutation_rate
        val = low + rand * (high-low)
      else
        variation = 1 + (rand * 2 * SMALL_MUTATION_AMOUNT) - SMALL_MUTATION_AMOUNT
        val = old_val * variation
        val = low if low and val < low
        val = high if high and val > high
      end
    else # not used yet; it seems we will always have limits for valid values
      # add or remove up to 5
      val = old_val + (rand - 0.5) * 10
    end
    return val
  end

  def mutate_all!
    @map.each_key do |key|
      @map[key] = mutation1(key,@map[key],1.0)
    end
    return self
  end  

end
