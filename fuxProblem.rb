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
end

class Constraint
	attr_reader :vars
	def initialize(vars)
		@vars = vars
	end
	def satisfied?
		raise "Satisfied not defined (abstract method)"
	end
end

class Variable
	attr_accessor :value
	def domain
		raise "Domain not defined (abstract method)"
	end
end


class Note
	include Comparable

	attr_reader :pitch
	attr_reader :octave

	Values = {
		"C" => 0,
		"C#" => 1,
		"D" => 2,
		"D#" => 3,
		"E" => 4,
		"F" => 5,
		"F#" => 6,
		"G" => 7,
		"G#" => 8,
		"A" => 9,
		"A#" => 10,
		"B" => 11
	}

	def initialize(dict)
		@value = dict
		@pitch = Values[dict[:value]]
		if @pitch.nil?
			raise(ArgumentError, "Invalid note value.")
		end
		@octave = dict[:octave]
	end

	def <=>(other)
		octave_difference = (@octave <=> other.octave)
		if octave_difference != 0
			return octave_difference
		else
			return @pitch <=> other.pitch
		end
	end

	def midiValue
		@pitch + 12*@octave
	end
end

class FuxProblem < Problem
	def initialize(chord_progression, key)
	end
end

class Chord
	# four notes, one each in range
end

# Tests
# Testing Note
require "minitest/autorun"
require "minitest/reporters"

reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]

class TestNote < MiniTest::Unit::TestCase
	def setup
		@c4 = Note.new({value: "C", octave: 4})
		@d3 = Note.new({value: "D", octave: 3})
		@a4 = Note.new({value: "A", octave: 4})
	end

	def test_badnote
		assert_raises ArgumentError do
			Note.new({value: "H", octave: 2})
		end
	end

	def test_note_comparison
		refute(@d3 < @d3)
		assert(@c4 == @c4)
		refute(@a4 > @a4)
		assert(@d3 < @c4)
		refute(@d3 == @a4)
		refute(@a4 < @c4)
		refute(@c4 < @d3)
		refute(@a4 == @d3)
		assert(@c4 < @a4)
	end

	def test_midiValue
		assert(@c4.midiValue == 48)
		assert(@d3.midiValue == 38)
		assert(@a4.midiValue == 57)
	end
end