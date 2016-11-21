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
		raise "Satisfied not defined (call Matthew)"
	end
end

class Variable
	attr_accessor :state
	def domain
		raise "Domain not defined (call Matthew)"
	end
end

class Note
	include Comparable

	attr_reader :value
	attr_reader :octave

	def initialize(dict)
		@value = dict[:value]
		@octave = dict[:octave]
	end

	def <=>(other)
		octave_difference = (@octave <=> other.octave)
		if octave_difference != 0
			return octave_difference
		else
			return @value <=> other.value
		end
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

class TestNote < MiniTest::Unit::TestCase
	def setup
		@c4 = Note.new({value: "C", octave: 4})
		@d3 = Note.new({value: "D", octave: 3})
		@a4 = Note.new({value: "A", octave: 4})
	end

	def test_note_comparison
		assert_equal(@d3 <=> @d3, 0)
		assert_equal(@c4 <=> @c4, 0)
		assert_equal(@a4 <=> @a4, 0)
		assert_equal(@d3 <=> @c4, -1)
		assert_equal(@d3 <=> @a4, -1)
		assert_equal(@a4 <=> @c4, -1)
		assert_equal(@c4 <=> @d3, 1)
		assert_equal(@a4 <=> @d3, 1)
		assert_equal(@c4 <=> @a4, 1)
	end
end