require_relative "./Problem.rb"
require_relative "./note.rb"

class FuxProblem < Problem
	def initialize(chord_progression, key)
		# list of chords
		vars = {}
		chord_progression.each_with_index do |chord, i|
			vars << FuxChord(key, chord, i)
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
		@domain = []
		@id = id
		set_up_domain_properly(key, chordType)
	end

	def soprano
		@value[0]
	end

	def alto
		@value[1]
	end

	def tenor
		@value[2]
	end

	def bass
		@value[3]
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
						@domain << [s, a, t, b]
					end
				end
			end
		end
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

def FuxConstraint < Constraint
	def initialize(cType, vars)
		# cType is one of the types of constraints we have in FS4PH.
		case cType
		when :voices_must_be_within_octave

		end
	end
end