class Problem
    attr_reader :constraints
    attr_reader :vars

    # Easier to have each variable as a map for easier reference with an id
    def initialize
        @constraints = []
        @vars = {}
    end

    def new_var(id, domain: nil, assignment: nil)
        vars[id] = Variable.new(id, domain: domain, assignment: assignment)
    end

    # Returns the domain of a specific variable
    def domain_of(variable_id)
        variable = vars[variable_id]
        # If the variable or domain doesn't exist return [], else return domain
        variable.nil? || variable.domain.nil? ? [] : variable.domain
    end

    def new_constraint(*vars, &block)
        constraint = Constraint.new(vars: vars, blck: block)
        constraints.push(constraint)
    end

    # Make sure each assignment is valid
    def validate(assigned_var, assignments)
        constraints.each do |constraint|
            return false if constraint.var_qualifier?(assigned_var, assignments) && !constraint.valid(assignments)
        end
        return true
    end

    # Creates a map called assignments for each variable in order to keep track of assignments 
    def assign_vars
        @vars.reduce({}) do |assignments, (id, variable)|
            # If we have something to assign to the variable object, assign that
            assignments[id] = variable.assignment unless variable.assignment.nil?
            assignments
        end
    end

    def assign(csp = Solver.new(self))
        csp.assign(assign_vars)
    end


end

class Variable
    # ID and Domain of variable are self_Explanatory we choose it, as we initialize the Problem
    # The solver then assigns a specific value to the variable which is called the assignment
    attr_reader :id, :domain
    attr_accessor :assignment

    def initialize(id, domain: nil, assignment: nil)
        @id = id
        @domain = domain
        @assignment = assignment
    end
end

class Constraint
    attr_reader :vars, :blck

    def initialize(vars: nil, blck: nil)
        @vars = vars.flatten.compact
        @blck = blck
        if @blck.nil?
            raise ArgumentError
        end
    end

    def var_qualifier?(assigned_var, assignments)
        # Checks to make sure the variable you're assigning exist and isn't already assigned
        ((vars.include?(assigned_var) && vars.all?{ |v| assignments.key?(v) })) || vars.empty?
    end

    def valid(assignments)
        # return false unless blck => should still work?
        blck.call(*values_at(assignments), assignments)
    end

    def values_at(assignments)
        assignments.values_at(*vars)
    end
end

class Solver
    attr_reader :problem

    def initialize(problem)
        @problem = problem
    end

    # Checks if all assignments have been made
    def done?(assignments)
        assignments.size == problem.vars.size
    end

    # Returns list of available values to assign
    def next_available_var(assignments)
        problem.vars.reject { |x| assignments.include?(x) }.each_value.first
    end

    # Gets domin of specific variable
    def domain_of(var)
        problem.domain_of(var.id)
    end

    # Checks if the assignment was okay
    def satisfied?(assignment, assignments)
        problem.validate(assignment, assignments)
    end

    def assign(assignments = {})
        return assignments if done?(assignments)
        var = next_available_var(assignments)
        domain_of(var).each do |value|
            assigned = assignments.merge(var.id => value)
            if satisfied?(var.id, assigned)
                result = assign(assigned)
                return result if result
            end
        end
        return false
    end
end

problem = Problem.new

problem.new_var :a, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
problem.new_var :b, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
problem.new_var :c, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
problem.new_var :d, domain: [7, 8, 9, 10, 11]
problem.new_var :e, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

problem.new_constraint(:b, :c) { |b, c| b > c }
problem.new_constraint(:b) { |a| a % 3 == 0 }
problem.new_constraint(:b, :a) { |b, a| b == a * 2 }
problem.new_constraint(:a, :b, :c, :e) {|a, b, c, d| a + b + c + d > 40}
problem.new_constraint(:c, :a) { |c, a| c > a }

puts problem.assign  