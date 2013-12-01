
class TimeKeeper

  # tolerance allows you to ignore a bad performance to some extent. E.g 1.05 gives you 5% tolerance up
  # ratio allows you to adapt to slower or faster system. E.g 1.0 if your system is as slow as mine :(
  def initialize(tolerance = 1.15, ratio = 1.0)
    @tolerance = tolerance
    @ratio = ratio
    set_gc_tolerance # in number of times over the expected number or runs
  end
  
  # Sets the GC runs tolerance
  # I.e. how many times over the expected number of GC run can we tolerate.
  # Note this number is increased using the general tolerance percentage give at init.
  def set_gc_tolerance(num_runs = 10)
    @gc_tolerance = num_runs * @tolerance
  end

  # Call this before start() if you want to compute the ratio automatically
  # NB: measures will always vary a bit unless we find the perfect calibration code (utopia)
  def calibrate(expected)
    t0 = Time.now
    2000.times do
      m = {}
      100.times { |n| m[n.to_s] = n }
      1000.times { |n| m[n.modulo(100).to_s] += 1 }
    end
    duration = Time.now - t0
    @ratio = duration / expected
    puts "TimeKeeper calibrated at ratio=#{'%.02f' % @ratio} "+
    	"(ran calibration in #{'%.03f' % duration} instead of #{expected})"
  end
  
  # Starts timing
  # the expected time given will be adjusted according to the current calibration
  def start(task_name, expected_in_sec, expected_gc)
    @task_name = task_name
    @expected_time = expected_in_sec * @ratio
    @expected_gc = expected_gc.round
    puts "Started \"#{task_name}\"..." # (expected time #{'%.02f' % @expected_time}s)..."
    @gc0 = GC.count
    @t0 = Time.now
  end

  # Stops timing, displays the report and raises exception if we went over limit
  # Unless raise_if_overlimit is false, in which case we would simply log and return the error message
  def stop(raise_if_overlimit = true)
    @duration = Time.now - @t0
    @num_gc = GC.count - @gc0
    puts " => "+result_report
    check_limits(raise_if_overlimit)
  end
  
  def result_report
    s = ""
    s << "Measuring \"#{@task_name}\":"
    s << " time: #{'%.02f' % @duration}s (expected #{'%.02f' % @expected_time} hence #{'%.02f' % (@duration / @expected_time * 100)}%)"
    s << " GC runs: #{@num_gc} (#{@expected_gc})"
  end

private

  def check_limits(raise_if_overlimit)
    if @duration > @expected_time * @tolerance
      msg1 = "Duration over limit: #{@duration}" 
      raise msg1 if raise_if_overlimit
      return msg1
    end
    if @num_gc > @expected_gc + @gc_tolerance
      msg2 = "GC run number over limit: #{@num_gc}"
      raise msg2 if raise_if_overlimit
      return msg2
    end
    return ""
  end

end
