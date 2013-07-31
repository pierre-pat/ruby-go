

class Stone
	@@color_names=["black","white","red","blue"]
	@@color_chars="O*X@"

	def Stone.init(numColors)
		raise "Max player number is "+@@color_names.size.to_s if numColors>@@color_names.size
	end

	def initialize(color)
		@color = color
		@group = nil
	end

	def display
		print @@color_chars[@color]
	end

	def Stone.color_name(color)
		return @@color_names[color]
	end
end

class Group
	def initialize(stone)
		@stones=[stone]
	end

	def Group.connects(goban, i, j, color)
		
	end
end




