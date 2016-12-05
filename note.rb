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

	# determine by major scale how to translate chordType into an offset value
	# C C# D D# E F F# G G# A A# B
	# 0 1  2 3  4 5 6  7 8  9 10 11
	MajorScale = [0, 2, 4, 5, 7, 9, 11]

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

	def in_triad?(key, chordType)
		# dealing with 1-indexing
		chordType -= 1
		keyPitchNum = NameToValue[key]
		root = keyPitchNum + MajorScale[chordType % 7]
		root %= 12
		third = keyPitchNum + MajorScale[(chordType + 2) % 7]
		third %= 12
		fifth = keyPitchNum + MajorScale[(chordType + 4) % 7]
		fifth %= 12
		[root, third, fifth].include? @pitchNum
	end
end