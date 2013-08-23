
class TimeKeeper

  # tolerance allows you to ignore a bad performance to some extent. E.g 1.05 gives you 5% tolerance up
  # ratio allows you to adapt to slower or faster system. E.g 1.0 if your system is as slow as mine :(
  def initialize(tolerance = 1.15, ratio = 1.0)
    @tolerance = tolerance
    @ratio = ratio
  end

  # Call this before start() if you want to compute the ratio automatically
  # NB: measures will always vary a bit unless we find the perfect calibration test (utopia)
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
    	"(ran calibration test in #{'%.03f' % duration} instead of #{expected})"
  end
  
  # Starts timing
  # the expected time given will be adjusted according to the current calibration
  def start(test_name, expected_in_sec, expected_gc)
    @test_name = test_name
    @expected_time = expected_in_sec * @ratio
    @expected_gc = expected_gc
    puts "Started test \"#{test_name}\"..." # (expected time #{'%.02f' % @expected_time}s)..."
    @gc0 = GC.count
    @t0 = Time.now
  end

  # Stops timing, display the report and throw exception if we went over limit
  def stop
    @duration = Time.now - @t0
    @num_gc = GC.count - @gc0
    puts " => "+result_report
    check_limits
  end
  
  def result_report
    s = ""
    s << "Test \"#{@test_name}\":"
    s << " time: #{'%.02f' % @duration}s (expected #{'%.02f' % @expected_time} hence #{'%.02f' % (@duration / @expected_time * 100)}%)"
    s << " GC runs: #{@num_gc} (#{@expected_gc})"
  end

private
  def check_limits
    raise "Duration over limit: #{@duration}" if @duration > @expected_time * @tolerance
    raise "GC run number over limit: #{@num_gc}" if @num_gc > @expected_gc * @tolerance
  end
end
