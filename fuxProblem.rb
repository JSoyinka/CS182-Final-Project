###############################################################################
# Abstract classes Problem, Constraint, and Variable
#
# Must conform to the APIs
#   Problem#vars
#     -> returns an ordered list of domains. Each domain corresponds to a var.
#   Problem#constraints
#     -> returns a list of Constraint objects that use those vars.
#   
#   Constraint#vars
#     -> returns a list of vars constrained by this constraint
#   Constraint#satisfied?
#     -> returns a bool indicating whether this constraint is currently met.
#
#   Variable#domain
#     -> returns the list of all possible values it can hold.
#   Variable#value
# 		-> gets the current state of the variable
#        If we have yet to assign a value to this variable, then returns nil.
#   Variable#value=(value_i)
#     -> sets the variable to the value specified in value_i
#
###############################################################################

class Problem
	attr_reader :vars
	attr_reader :constraints
	def initialize
		@vars = []
		@constraints = []
	end
	# Might want to create a function that returns domain of a specific var here
	# instead of double indexing
end

class Constraint
	attr_reader :vars
	def initialize(vars)
		@vars = vars
	end
	def satisfied?(assignments)
		raise "Satisfied not defined (abstract method)"
	end
end

class Variable
	attr_accessor :value
	def domain
		raise "Domain not defined (abstract method)"
	end
end


require_relative "./note.rb"

class FuxProblem < Problem
	def initialize(chord_progression, key)
	end
end

class FuxChord < Variable
	def initialize(key, chordType)
		# eventually [soprano, alto, tenor, bass]
		@value = [nil, nil, nil, nil]
		@domain = []
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
		# ????
		# Determine all valid bass notes, all valid tenor, all valid alto, all valid soprano.
		# iterate through bass range
	end

	def ensure_within_ranges
		@soprano = @value[0]
		@alto    = @value[1]
		@tenor   = @value[2]
		@bass    = @value[3]
		# Ensure that notes are within the ranges of the singers.
		soprano_top_note = Note.new({pitch: "C", octave: 6})
		soprano_bot_note = Note.new({pitch: "C", octave: 4})
		unless @soprano.between?(soprano_bot_note, soprano_top_note)
			raise ArgumentError, "Soprano out of range."
		end
		alto_top_note = Note.new({pitch: "F", octave: 5})
		alto_bot_note = Note.new({pitch: "F", octave: 3})
		unless @alto.between?(alto_bot_note, alto_top_note)
			raise ArgumentError, "Alto out of range."
		end
		tenor_top_note = Note.new({pitch: "C", octave: 5})
		tenor_bot_note = Note.new({pitch: "C", octave: 3})
		unless @tenor.between?(tenor_bot_note, tenor_top_note)
			raise ArgumentError, "Tenor out of range."
		end
		bass_top_note = Note.new({pitch: "E", octave: 4})
		bass_bot_note = Note.new({pitch: "E", octave: 2})
		unless @bass.between?(bass_bot_note, bass_top_note)
			raise ArgumentError, "Bass out of range."
		end
	end
end