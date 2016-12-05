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
	attr_reader :id
	attr_accessor :assignment
	attr_reader :domain
end