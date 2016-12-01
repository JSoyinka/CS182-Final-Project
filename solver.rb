require "fuxProblem"

class Solver
	def initialize(problem)
     	@problem = problem
    end

    attr_reader :problem

    # Checks if all assignments have been made
    def done?(assignments)
      	assignments.size == problem.vars.size
    end

    # Returns list of available values to assign
    def next_available_var(assignments)
      	problem.variables.reject { |x| assignments.include?(x) }
    end

    # Gets domin of specific variable
    def domain_of(var)
      	problem.vars[var].domain
    end

    # Checks if the assignment was okay
    def satisfied?(assignments)
      	problem.constraint.satisfied?(new_assigns)
    end

    # Assings that shit
    def assign(assignments = [])
      	return assignments if done?(assignments)
      	var = next_available_var(assignments)
      	domain_of(var).each do
        	if satisfied?(assignments)
          		result = assign(assignments)
          		return result if result
        	end
      	end
      	return false
    end
end