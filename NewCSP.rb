require "byebug"

class Problem
  attr_reader :constraints
  attr_reader :vars
  attr_accessor :assignments

  # Easier to have each variable as a map for easier reference with an id
  def initialize
    @constraints = []
    @vars = {}
    @assignments = {}
  end

  # Create a new variable
  def new_var(id, domain: nil, assignment: nil)
    vars[id] = Variable.new(id, domain: domain, assignment: assignment)
  end

  # Create a new constraint
  def new_constraint(*vars, &block)
    constraint = Constraint.new(vars: vars, blck: block)
    constraints.push(constraint)
  end

  # Make sure each assignment is valid
  def validate(assigned_var, assignments)
    constraints.each do |constraint|
      # First checks to see if the constraint applies to the new variable, then checks if the assignment is valid
      return false if constraint.relevant_vars_assigned?(assignments) && !constraint.valid?(assignments)
    end
    return true
  end

  # Creates a map called assignments for each variable in order to keep track of assignments 
  # def assign_vars
  #   @vars.reduce({}) do |assignments, (id, variable)|
  #     # If we have something to assign to the variable object, assign that
  #     @assignments[id] = variable.assignment unless variable.assignment.nil?
  #     @assignments
  #   end
  # end

  # Classic CSP forward_check
  def forward_check(assignments)
    # Gather unassigned vars, loop through them and each constraint
    not_assigned = vars.reject { |x| assignments.include?(x) }
      not_assigned.each_value do |var|
        constraints.each do |constraint|
          #Create a temporary clone of assignments to test valid future choices
          temp = assignments.clone
          # Add the variable we want to test
          temp.merge!(var.id => nil)
          # Continue if the new variable is part of the constraint and every other variable in the constraint has been assigned
          if constraint.vars.include?(var.id) && constraint.relevant_vars_assigned?(temp)
            prune = []
            var.domain.each do |value|
              temp.merge!(var.id => value)
              # If the new variable wouldn't work add it to the prune list
              prune << value if !constraint.valid?(temp)
            end
            # Prune those values
            prune.each() { |x| var.domain.delete(x) }
            return false if var.domain.empty?
          end
        end
      end
  end

  # Run that backtrack search
  def assign(csp = Solver.new(self))
    byebug
    csp.assign({})
  end

  # Restore the domain of variables we pruned
  def unprune_vars
    vars.each_value do |var|
      var.unprune
    end
  end
end

class Variable
  # ID and Domain of variable are self_Explanatory we choose it, as we initialize the Problem
  # The solver then assigns a specific value to the variable which is called the assignment
  attr_reader :id, :init_domain
  attr_accessor :assignment, :domain

  def initialize(id, domain: nil, assignment: nil)
      @id = id
      @domain = domain
      @assignment = assignment
      @init_domain = domain.clone
  end

  def unprune()
    @domain = @init_domain.clone
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

  # Checks if a given variable is constrained by the current constraint object 
  # (i.e. if the constraint applies to Var1 and Var2, we shouldn't run it on Var 3)
  def relevant_vars_assigned?(assignments)
      vars.all?{ |v| assignments.key?(v) } || vars.empty?
  end

  # def fcheck_constrained?(assignments)
  #     vars.all?{ |v| assignments.include?(v) }
  # end

  # Checks to see if the assignment has a new variable
  def valid?(assignments)
      blck.call(*vals_for(assignments), assignments)
  end

  # Gets relevant values for specific variables
  # Matthew doesn't have to implement this.
  def vals_for(assignments)
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

  # Checks if the assignment was okay
  def satisfied?(assignment, assignments)
    problem.validate(assignment, assignments)
  end


  # Backtrack function
  def assign(assignments = {})
    return assignments if done?(assignments)
    var = next_available_var(assignments)
    var.domain.each do |value|
      # Assigned the next possible value
      assigned = assignments.merge(var.id => value)
      # assignments.clone[var.id] = value
      # If forward check completely pruned the domain of a variable choose another value assignment
      unless problem.forward_check(assigned)
        problem.unprune_vars
        next
      end
      # Check to see if that assignment was valid
      if satisfied?(var.id, assigned)
        solution = assign(assigned)
        return solution if solution
      end
    end
    return false
  end
end

problem = Problem.new
# problem.new_var :a, domain: [1, 2, 3, 4, 5]
# problem.new_var :b, domain: [1, 2, 3, 4, 5]
# problem.new_var :c, domain: [1, 2, 3, 4, 5]
# problem.new_var :d, domain: [1, 2, 3, 4, 5]

# problem.new_constraint(:a, :b) { |a, b| a > b }
# problem.new_constraint(:b, :c) { |b, c| b < c}
# problem.new_constraint(:a, :c, :d) { |a, c, d| a + c <= d}


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