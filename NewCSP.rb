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

  ## SECTION FOR INITIALIZING A PRONBLEM##

  # Create a new variable
  def new_var(id, domain: nil, assignment: nil)
    vars[id] = Variable.new(id, domain: domain, assignment: assignment)
  end

  # Create a new constraint
  def new_constraint(*vars, &block)
    constraint = Constraint.new(vars: vars, blck: block)
    constraints.push(constraint)
  end

  ## SECTION FOR BACKTRACK FUNCTIONS##

  # Make sure each assignment is valid
  def satisfied?(new_var, assignments)
    constraints.each do |constraint|
      # First checks to see if the constraint applies to the new variable, then checks if the assignment is valid
      return false if constraint.var_is_constrained?(new_var, assignments) && !constraint.valid(assignments)
    end
    return true
  end

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
          if constraint.var_is_constrained?(var.id, temp)
            prune = []
            var.domain.each do |value|
              temp.merge!(var.id => value)
              # If the new variable wouldn't work add it to the prune list
              prune << value if !constraint.valid(temp)
            end
            # Prune those values
            prune.each() { |x| var.domain.delete(x) }
            return false if var.domain.empty?
          end
        end
      end
  end

  def backtrack_done?(assignments)
    assignments.size == vars.size
  end

  # Returns list of available values to assign
  def next_available_var(assignments)
    vars.reject { |x| assignments.include?(x) }.each_value.first
  end

  # Backtrack function
  def backtrack(assignments = {})
    return assignments if backtrack_done?(assignments)
    var = next_available_var(assignments)
    var.domain.each do |value|
      # Assigned the next possible value
      assigned = assignments.merge(var.id => value)
      # If forward check completely pruned the domain of a variable choose another value assignment
      unless forward_check(assigned)
        unprune_vars
        next
      end
      # Check to see if that assignment was valid
      if satisfied?(var, assigned)
        solution = backtrack(assigned)
        return solution if solution
      end
    end
    return false
  end

  ## SECTION FOR RANDOM MIN CONFLICTS FUNCTIONS ##

  def mc_satisfied?(assignments)
    constraints.each do |constraint|
      # First checks to see if the constraint applies to the new variable, then checks if the assignment is valid
      return false if !constraint.valid(assignments)
    end
    return true
  end

  def count_constraints(id, assignments)
    conflicts = 0
    constraints.each do |constraint|
      if !constraint.var_is_constrained?(id, assignments)
        next 
      elsif !constraint.valid(assignments)
        conflicts += 1
      end
    end
    return conflicts
  end
  
  def best_value(id, assignments)
    best_val = nil
    min_conflicts = vars[id].domain.size + 1
    vars[id].domain.each do |val|
      # First checks to see if the constraint applies to the new variable, then checks if the assignment is valid
      assignments[id] = val
      conflicts = count_constraints(id, assignments)
      if conflicts < min_conflicts
        best_val = val
        min_conflicts = conflicts
      end
    end
    assignments[id] = best_val
    return assignments
  end

  def rmc_assign(assignments = {})
    return assignments if mc_satisfied?(assignments)
    assignments.keys.each do |id| 
      assignments = best_value(id, assignments)
      puts id
      puts assignments
    end
    return rmc_assign(assignments)
  end


  def rand_min_conflicts()
    random_hash = {}
    vars.keys.shuffle.each do |var|
      random_hash[var] = vars[var].domain.sample
    end
    rmc_assign(random_hash)
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
  def var_is_constrained?(new_var, assignments)
      vars.include?(new_var) && vars.all?{ |v| assignments.key?(v) } || vars.empty?
  end

  # Checks to see if the assignment has a new variable
  def valid(assignments)
      blck.call(*vals_for(assignments), assignments)
  end

  # Gets relevant values for specific variables
  def vals_for(assignments)
      assignments.values_at(*vars)
  end
end


problem = Problem.new
problem.new_var :a, domain: [1, 2, 3, 4, 5]
problem.new_var :b, domain: [1, 2, 3, 4, 5]
problem.new_var :c, domain: [1, 2, 3, 4, 5]
problem.new_var :d, domain: [1, 2, 3, 4, 5, 6, 7, 8]

problem.new_constraint(:a, :b) { |a, b| a > b }
problem.new_constraint(:b, :c) { |b, c| b < c}
problem.new_constraint(:a, :c, :d) { |a, c, d| a + c <+ d}


# problem.new_var :a, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
# problem.new_var :b, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
# problem.new_var :c, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
# problem.new_var :d, domain: [7, 8, 9, 10, 11]
# problem.new_var :e, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

# problem.new_constraint(:b, :c) { |b, c| b > c }
# problem.new_constraint(:b) { |a| a % 3 == 0 }
# problem.new_constraint(:b, :a) { |b, a| b == a * 2 }
# problem.new_constraint(:a, :b, :c, :e) {|a, b, c, d| a + b + c + d > 40}
# problem.new_constraint(:c, :a) { |c, a| c > a }

puts problem.rand_min_conflicts