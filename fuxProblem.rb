require_relative "./NewCSP.rb"
require_relative "./note.rb"

class FuxProblem < Problem
	def initialize(chord_progression, key)
		# hash of chords as vars. Very important that we are zero indexed...
		@vars = {}
		chord_progression.each_with_index do |chord, i|
			@vars[i] = FuxChord.new(key, chord, i)
		end
		@constraints = []
		@soft_constraints = []
		@assignments = {}
		# add all constraints between the vars.
		# first pass: add unary constraints.
		numChords = @vars.length
		0.upto(numChords) do |i|
			# Distance between voices cannot exceed an octave (except tenor/bass).
			@constraints << DoesThisWorkConstraint.new(@vars[i])
			@constraints << VoicesWithinOctave.new(@vars[i])
			unless i == numChords - 1
				@constraints << DoublingRulesNonTerminal.new(@vars[i])
			end 
		end
		@constraints << DoublingRulesTerminal.new(@vars[numChords - 1])
		# second pass: add binary constraints
		0.upto(numChords - 1) do |i|
			# @constraints << SampleBinaryConstraint.new(@vars[i], @vars[i+1])
			# @constraints << ResolveSevenths.new(@vars[i], @vars[i+1])
		end
		# third pass: add ternary constraints
		0.upto(numChords - 2) do |i|
			# @constraints << SampleTernaryConstraint.new(@vars[i], @vars[i+1], @vars[i+2])
		end
	end
end

class FuxChord < Variable
	attr_reader :key
	attr_reader :root
	attr_reader :third
	attr_reader :fifth

	Ranges = {
		soprano: {
			top: Note.new("C6"),
			bot: Note.new("C4")
		},
		alto: {
			top: Note.new("F5"),
			bot: Note.new("F3")
		},
		tenor: {
			top: Note.new("C5"),
			bot: Note.new("C3")
		},
		bass: {
			top: Note.new("E4"),
			bot: Note.new("E2")
		}
	}

	# determine by major scale how to translate chordType into an offset value
	# C C# D D# E F F# G G# A A# B
	# 0 1  2 3  4 5 6  7 8  9 10 11
	MajorScale = [0, 2, 4, 5, 7, 9, 11]

	def initialize(key, chordType, id)
		# [soprano, alto, tenor, bass]
		@assignment = [nil, nil, nil, nil]
		@init_domain = []
		@id = id

		chordType -= 1
		keyPitchNum = Note::NameToValue[key]
		@root = keyPitchNum + MajorScale[chordType % 7]
		@root %= 12
		@third = keyPitchNum + MajorScale[(chordType + 2) % 7]
		@third %= 12
		@fifth = keyPitchNum + MajorScale[(chordType + 4) % 7]
		@fifth %= 12

		set_up_domain_properly()
	end

	def can_contain_pitch?(note)
		return [@root, @third, @fifth].include? note.pitchNum
	end

	def soprano
		@assignment[0]
	end

	def alto
		@assignment[1]
	end

	def tenor
		@assignment[2]
	end

	def bass
		@assignment[3]
	end

	def set_up_domain_properly()
		# The strategy will be to first construct all combinations of four notes that fit the key and chord.
		# Later, we will filter out ones that do not agree with our unbreakable unary constraints.
		(Ranges[:soprano][:bot]..Ranges[:soprano][:top]).each do |s|
			next unless can_contain_pitch?(s)
			(Ranges[:alto][:bot]..Ranges[:alto][:top]).each do |a|
				next unless can_contain_pitch?(a)
				(Ranges[:tenor][:bot]..Ranges[:tenor][:top]).each do |t|
					next unless can_contain_pitch?(t)
					(Ranges[:bass][:bot]..Ranges[:bass][:top]).each do |b|
						next unless can_contain_pitch?(b)
						@init_domain << [s, a, t, b]
					end
				end
			end
		end
		@domain = init_domain.clone
	end

	def ensure_within_ranges
		# Ensure that notes are within the ranges of the singers.
		unless @soprano.between?(Ranges[:soprano][:bot], Ranges[:soprano][:top])
			raise ArgumentError, "Soprano out of range."
		end
		unless @alto.between?(Ranges[:alto][:bot], Ranges[:alto][:top])
			raise ArgumentError, "Alto out of range."
		end
		unless @tenor.between?(Ranges[:tenor][:bot], Ranges[:tenor][:top])
			raise ArgumentError, "Tenor out of range."
		end
		unless @bass.between?(Ranges[:bass][:bot])
			raise ArgumentError, "Bass out of range."
		end
	end

	def to_s
		return "Chord #{i}: #{@root} #{@third} #{@fifth}; assignment: [#{soprano.to_s}, #{alto.to_s}, #{tenor.to_s}, #{bass.to_s}]"
	end
end

class VoicesWithinOctave < Constraint
	def initialize(chord)
		@vars = [chord]
		@function = lambda do
			
		end
	end

	def valid?
		# is soprano within octave of alto?
		# is alto within octave of tenor?
		chord = @vars[0]
		soprano_and_alto = (chord.soprano.within?(12, chord.alto))
		alto_and_tenor = (chord.alto.within?(12, chord.tenor))
		# only true when both are true.
		return soprano_and_alto && alto_and_tenor
	end
end

class DoublingRulesNonTerminal < Constraint
	# Doubling rules:
	#  If chord is not 7:
	#   Best: root x2, third x1, fifth x1
	#   Next best: root x1, third x1, fifth x2
	#   Next best: root x1, third x2, fifth x1
	#   Next best: root x3, third x1
	#   all others are unacceptable
	def initialize(chord)
		@vars = [chord]
	end

	def valid?
		# Make sure all 3 notes are represented.
		return @vars[0].uniq.length == 3
	end
end

class DoublingRulesTerminal < Constraint
	def initialize(chord)
		@vars = [chord]
	end

	def valid?
		# Either all notes represented, or there are three roots.
		if @vars[0].uniq.length == 3
			return true
		end
		# Ensure we have 3 roots and 1 third.
		numRoots = 0
		numThirds = 0
		@vars[0].each do |note|
			if note.pitchNum == @vars[0].root
				numRoots += 1
			elsif note.pitchNum == @vars[0].third
				numThirds += 1
			end
		end
		return numRoots == 3 && numThirds == 1
	end
end

class DoesThisWorkConstraint < Constraint
	def initialize(chord)
		@vars = [chord]
	end
	def valid?
		false
	end
end

testlol = FuxProblem.new([1, 7, 1], "C")
d = testlol.assign
0.upto(2) { |x| puts "#{d[x].map(&:to_s)}"}