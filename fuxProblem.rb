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
		numChords = @vars.length
		# first pass: add binary constraints
		0.upto(numChords - 2) do |i|
			@constraints << NoParallelMotionOuterVoices.new(@vars[i], @vars[i+1])
			@constraints << NoSimilarToPerfectOuterVoices.new(@vars[i], @vars[i+1])
			@constraints << NoForbiddenParallels.new(@vars[i], @vars[i+1])
			@constraints << NoSkipsGreaterThanOctave.new(@vars[i], @vars[i+1])
			@constraints << ResolveSevenths.new(@vars[i], @vars[i+1])
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
	attr_reader :id
	attr_reader :assignment

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
		@domain = []
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
		@init_domain.each do |values|
			varValues = values.map(&:pitchNum)
			s = values[0]
			a = values[1]
			t = values[2]
			b = values[3]
			soprano_and_alto = (s.within?(12, a))
			alto_and_tenor = (a.within?(12, t))
			if soprano_and_alto && alto_and_tenor && varValues.uniq.length == 3
				if (s>=a) && (a>=t) && (t>=b)
					@domain << values
				end
			end
		end
		# @domain.each {|chord| puts "#{chord.map(&:to_s)}"}
		@domain.shuffle!
		@init_domain = domain.clone
		# @domain = @init_domain.clone
		# puts @domain.length
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

# For testing purposes only.
class DoesThisWorkConstraint < Constraint
	def initialize(chord)
		@vars = []
	end
	def valid(a)
		false
	end
end

def sign(int)
	if int == 0 then return :z end
	if int == int.abs then :+ else :- end
end

class NoParallelMotionOuterVoices < Constraint
	def initialize(var1, var2)
		@vars = [var1.id, var2.id]
	end

	def valid(assignment)
		first_chord = assignment[@vars[0]]
		second_chord = assignment[@vars[1]]
		# cannot be same interval in same direction.
		s_direction = first_chord[0].midiValue - second_chord[0].midiValue
		b_direction = first_chord[3].midiValue - second_chord[3].midiValue
		return s_direction != b_direction
	end
end

class NoSimilarToPerfectOuterVoices < Constraint
	def initialize(var1, var2)
		@vars = [var1.id, var2.id]
	end
	def valid(assignment)
		first_chord = assignment[@vars[0]]
		second_chord = assignment[@vars[1]]
		s_direction = sign(first_chord[0].midiValue - second_chord[0].midiValue)
		b_direction = sign(first_chord[3].midiValue - second_chord[3].midiValue)
		if s_direction == b_direction
			# in the second chord, is it a perfect interval?
			if [0, 5, 7].include?((second_chord[0].pitchNum - second_chord[3].pitchNum) % 12)
				return false
			end
		end
		true
	end
end

class NoForbiddenParallels < Constraint
	def initialize(var1, var2)
		@vars = [var1.id, var2.id]
	end
	def valid(assignment)
		first_chord = assignment[@vars[0]]
		second_chord = assignment[@vars[1]]
		differences = [
			second_chord[0].midiValue - first_chord[0].midiValue,
			second_chord[1].midiValue - first_chord[1].midiValue,
			second_chord[2].midiValue - first_chord[2].midiValue,
			second_chord[3].midiValue - first_chord[3].midiValue
		]
		# Check for forbidden parallels (fifths, octaves) in each of them.
		[0, 1, 2, 3].permutation(2).each do |i1, i2|
			if differences[i1] == differences[i2]
				if [0, 7].include? differences[i1].abs
					return false
				end
			end
		end
	end
end

class NoSkipsGreaterThanOctave < Constraint
	def initialize(var1, var2)
		@vars = [var1.id, var2.id]
	end
	def valid(assignment)
		first_chord = assignment[@vars[0]]
		second_chord = assignment[@vars[1]]
		differences = [
			second_chord[0].midiValue - first_chord[0].midiValue,
			second_chord[1].midiValue - first_chord[1].midiValue,
			second_chord[2].midiValue - first_chord[2].midiValue,
			second_chord[3].midiValue - first_chord[3].midiValue
		]
		return differences.all? {|n| n.abs <= 12}
	end
end

class ResolveSevenths < Constraint
	def initialize(var1, var2)
		@vars = [var1.id, var2.id]
	end
	def valid(assignment)
		first_chord = assignment[@vars[0]]
		second_chord = assignment[@vars[1]]
	end
end

LEN_INPUT = 8
testlol = FuxProblem.new([1,4,5,4,5,1,4,1], "C")
# puts testlol.vars
# puts testlol.constraints
d = testlol.backtrack
# puts d
chordList = []
0.upto(LEN_INPUT - 1) { |x| chordList << d[x] }
0.upto(LEN_INPUT - 1) { |x| puts "#{chordList[x].map(&:to_s)}" }

require 'midilib/sequence'
require 'midilib/consts'
include MIDI

seq = Sequence.new()

# Create a first track for the sequence. This holds tempo events and stuff
# like that.
track = Track.new(seq)
seq.tracks << track
track.events << Tempo.new(Tempo.bpm_to_mpq(120))
track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')

# Create a track to hold the notes. Add it to the sequence.
track = Track.new(seq)
seq.tracks << track

# Give the track a name and an instrument name (optional).
track.name = 'My New Track'
# puts GM_PATCH_NAMES[52]
track.instrument = GM_PATCH_NAMES[52]

# Add a volume controller event (optional).
track.events << Controller.new(0, CC_VOLUME, 127)

# Add events to the track: a major scale. Arguments for note on and note off
# constructors are channel, note, velocity, and delta_time. Channel numbers
# start at zero. We use the new Sequence#note_to_delta method to get the
# delta time length of a single quarter note.
track.events << ProgramChange.new(0, 1, 0)
quarter_note_length = seq.note_to_delta('quarter')
chordList.each do |chord|
	chord.each do |note|
		track.events << NoteOn.new(0, note.midiValue, 127, 0)
	end
	length_of_time = quarter_note_length * 2
	chord.each do |note|
		track.events << NoteOff.new(0, note.midiValue, 127, length_of_time)
		length_of_time = 0
	end
end
# [0, 2, 4, 5, 7, 9, 11, 12].each do |offset|
#   track.events << NoteOn.new(0, 64 + offset, 127, 0)
#   track.events << NoteOn.new(0, 64 + offset + 4, 127, 0)
#   track.events << NoteOff.new(0, 64 + offset, 127, quarter_note_length)
#   track.events << NoteOff.new(0, 64 + offset + 4, 127, 0)
#   track.events << NoteOn.new(0, 64 + offset, 127, 0)
#   track.events << NoteOn.new(0, 64 + offset + 4, 127, 0)
#   track.events << NoteOff.new(0, 64 + offset, 127, quarter_note_length)
#   track.events << NoteOff.new(0, 64 + offset + 4, 127, 0)
# end

# Calling recalc_times is not necessary, because that only sets the events'
# start times, which are not written out to the MIDI file. The delta times are
# what get written out.

# track.recalc_times

File.open('real_results.mid', 'wb') { |file| seq.write(file) }