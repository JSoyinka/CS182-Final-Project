class Note
	include Comparable

	attr_reader :pitchNum
	attr_reader :octave

	# Set up class constants.
	relations = [
		["C", 0],
		["C#", 1],
		["D", 2],
		["D#", 3],
		["E", 4],
		["F", 5],
		["F#", 6],
		["G", 7],
		["G#", 8],
		["A", 9],
		["A#", 10],
		["B", 11]
	]

	values = {}
	inverseValues = {}
	relations.each do |r|
		pitch = r[0]
		number = r[1]
		values[r[0]] = r[1]
		inverseValues[r[1]] = r[0]
	end


	NameToValue = values
	ValueToName = inverseValues

	def initialize(str)
		# assumes octave will always be between 0 and 9, which is reasonable.
		@octave = str[-1].to_i
		pitchName = str.chop

		@pitchNum = NameToValue[pitchName]
		if @pitchNum.nil?
			raise(ArgumentError, "Invalid note value.")
		end
	end

	def <=>(other)
		octave_difference = @octave - other.octave
		if octave_difference != 0
			return octave_difference
		else
			pitchNumDifference = @pitchNum - other.pitchNum
			if pitchNumDifference != 0
				return pitchNumDifference
			end
		end
		return 0
	end

	def midiValue
		@pitchNum + 12*(@octave + 1)
	end

	def succ
		if @pitchNum == 11
			Note.new("#{ValueToName[0]}#{@octave + 1}")
		else
			Note.new("#{ValueToName[@pitchNum + 1]}#{@octave}")
		end
	end

	def to_s
		"#{ValueToName[@pitchNum]}#{octave}"
	end

	def within?(distance, otherNote)
		return (midiValue - otherNote.midiValue).abs <= distance
	end
end