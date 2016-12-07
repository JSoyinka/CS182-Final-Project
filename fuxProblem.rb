require_relative "./NewCSP.rb"
require_relative "./note.rb"

class FuxProblem < Problem
	def initialize(chord_progression, key)
		# list of chords as vars
		@vars = {}
		chord_progression.each_with_index do |chord, i|
			@vars[i] = FuxChord(key, chord, i)
		end
		@constraints = []
		@soft_constraints = []
		@assignments = {}
		# add all constraints between the vars.
		# first pass: add unary constraints.
		@vars.each do |chord|
			# Distance between voices cannot exceed an octave (except tenor/bass).
			@constraints << VoicesWithinOctave.new(chord)
			# Doubling rules:
			#  If chord is not 7:
			#   Best: root x2, third x1, fifth x1
			#   Next best: root x1, third x1, fifth x2
			#   Next best: root x1, third x2, fifth x1
			#   Next best: root x3, third x1
			#   all others are unacceptable
			#  If chord is 7:
			#   Best: root x1, third x1, fifth x2
			#   Next best: root x1, third x2, fifth x1
			#   others are unacceptable.
			# for right now, only the hardest version:
			#  Not 7: must be one of the above 4
			#  7 chord: must be one of the above 2
			@constraints << DoublingRules.new(chord)

			# 
		end
	end
end

class FuxChord < Variable
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
	def initialize(key, chordType, id)
		# [soprano, alto, tenor, bass]
		@assignment = [nil, nil, nil, nil]
		@init_domain = []
		@id = id
		set_up_domain_properly(key, chordType)
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

	def set_up_domain_properly(key, chordType)
		# The strategy will be to first construct all combinations of four notes that fit the key and chord.
		# Later, we will filter out ones that do not agree with our unbreakable unary constraints.
		(Ranges[:soprano][:bot]..Ranges[:soprano][:top]).each do |s|
			next unless s.in_triad?(key, chordType)
			(Ranges[:alto][:bot]..Ranges[:alto][:top]).each do |a|
				next unless a.in_triad?(key, chordType)
				(Ranges[:tenor][:bot]..Ranges[:tenor][:top]).each do |t|
					next unless t.in_triad?(key, chordType)
					(Ranges[:bass][:bot]..Ranges[:bass][:top]).each do |b|
						next unless b.in_triad?(key, chordType)
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
end

class VoicesWithinOctave < Constraint
	def initialize(chord)
		@vars = [chord]
		@function = lambda do
			# is soprano within octave of alto?
			# is alto within octave of tenor?
			soprano_and_alto = (chord.soprano.within?(12, chord.alto))
			alto_and_tenor = (chord.alto.within?(12, chord.tenor))
			# only true when both are true.
			return soprano_and_alto && alto_and_tenor
		end
	end

	def valid?
		# fetch variables from problem.
		@function.call()
	end
end

class DoublingRules < Constraint
	def initialize(chord)
		@vars = [chord]
	end
end
