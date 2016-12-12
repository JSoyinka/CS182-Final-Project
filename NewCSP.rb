require "byebug"

class Problem
  attr_reader :constraints
  attr_reader :soft_consts
  attr_reader :vars
  attr_accessor :assignments

  # Easier to have each variable as a map for easier reference with an id
  def initialize
    @constraints = []
    @soft_consts = []
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

  def new_soft_constraint(*vars, &block)
    soft_const = SoftConstraint.new(vars: vars, blck: block)
    soft_consts.push(soft_const)
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

  # Restore the domain of variables we pruned
  def unprune_vars(assigned)
    vars.reject{|id, key| assigned.include?(id)}.each_value do |var|
      var.unprune
    end
  end

  # Checks if the backtrack algorithm is done
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
        unprune_vars (assigned)
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

  ## SECTION FOR MIN CONFLICTS FUNCTIONS ##

  # Checks if min_conflicts
  def mc_satisfied?(assignments)
    constraints.each do |constraint|
      # Does not first check to make sure the constraints apply, because all assignments have been made
      return false if !constraint.valid(assignments)
    end
    return true
  end

  # Counting constraints, in order to find the least constrained value
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

  def most_soft_constraints(good_vals, id, assignments)
    max_satisfied = -1
    best_vals = []
    good_vals.each do |val|
      satisfied = 0
      assignments[id] = val
      soft_consts.each do |constraint|
        if !constraint.var_is_constrained?(id, assignments)
          next 
        elsif constraint.valid(assignments)
          satisfied += 1
        end
      end
      if satisfied == max_satisfied
        best_vals << val 
      elsif satisfied > max_satisfied
        best_vals = [val]
      end
    end
    assignments[id] = best_vals.sample
  end

  def least_constraining_value(id, assignments)
    # Better to keep the value the same, if there are conflicts
    curr_val = assignments[id]
    good_vals = [assignments[id]]
    min_conflicts = count_constraints(id, assignments)
    # Loops through values, besides the current one
    vars[id].domain.reject{|x| x == curr_val}.each do |val|
      # First checks to see if the constraint applies to the new variable, then checks if the assignment is valid
      assignments[id] = val
      conflicts = count_constraints(id, assignments)
      if conflicts == min_conflicts
        good_vals << val
      elsif conflicts < min_conflicts
        good_vals = [val]
        min_conflicts = conflicts
      end
    end
    # If there is more than one acceptable value, choose one other than the current
    if good_vals.size > 1
      # assignments[id] = good_vals.reject { |val| val == curr_val }.sample
      most_soft_constraints(good_vals, id, assignments)
    else
      assignments[id] = good_vals.first
    end
    return assignments
  end

  # Randomly select a variable that's constrained 
  def randomly_constrained_vars(assignments)
    conflicted_keys = []
    assignments.each_key do |id|
      constraints.each do |constraint|
        if !constraint.var_is_constrained?(id, assignments)
          next 
        elsif !constraint.valid(assignments)
          conflicted_keys << id
          break
        end
      end
    end
    return conflicted_keys
  end

  # Get most constrained variables
  def most_constrained_vars(assignments, last_var)
    most_conflicted_vars = []
    max_conflicts = 0
    assignments.reject{|id, val| id == last_var}.each_key do |id|
      conflicts = count_constraints(id, assignments)
      if conflicts == max_conflicts
        most_conflicted_vars << id
      elsif conflicts > max_conflicts
        most_conflicted_vars = [id] 
        max_conflicts = conflicts
      end 
    end
    return most_conflicted_vars
  end

  # This is the recursive min-conflicts algorithm
  def mc_assign(assignments = {}, last_var)
    return assignments if mc_satisfied?(assignments)
    constrained_vars =  most_constrained_vars(assignments, last_var)
    constrained_vars.delete(last_var)
    var = constrained_vars.sample
    return false if var.nil?
    assignments = least_constraining_value(var, assignments)
    puts assignments
    return mc_assign(assignments, var)
  end

  # Pass a randomized hash to the recursive min_conflicts algorithm
  def min_conflicts()
    random_hash = {}
    vars.each do |id, var|
      random_hash[id] = var.domain.sample
    end
    mc_assign(random_hash, random_hash.keys.sample)
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

class SoftConstraint
  attr_reader :vars, :blck, :weight

  def initialize(vars: nil, blck: nil, weight: nil)
      @vars = vars.flatten.compact
      @blck = blck
      @weight = weight
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
### Test Set 1 ###

# problem.new_var :a, domain: [1, 2, 3, 4, 5]
# problem.new_var :b, domain: [1, 2, 3, 4, 5]
# problem.new_var :c, domain: [1, 2, 3, 4, 5]
# problem.new_var :d, domain: [1, 2, 3, 4, 5]

# problem.new_constraint(:a, :b) { |a, b| a > b }
# problem.new_constraint(:b, :c) { |b, c| b < c}
# problem.new_constraint(:a, :c, :d) { |a, c, d| a + c <= d}
# problem.new_constraint(:a, :b, :c, :d) { |a, b, c, d| a + b + c + d >= 11}

### Test Set 2 ###

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


### Test Set 3 ###

problem.new_var :a, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
problem.new_var :b, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
problem.new_var :c, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
problem.new_var :d, domain: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

problem.new_constraint(:a, :b) { |a, b| a > b }
problem.new_constraint(:b, :c) { |b, c| b < c}
problem.new_constraint(:a, :c, :d) { |a, c, d| a + c > d}
problem.new_constraint(:a, :b, :c, :d) { |a, b, c, d| a + b + c + d >= 11}

problem.new_soft_constraint(:a) {|a| % 2 == 0}
problem.new_soft_constraint(:b) {|b| % 3 == 0}
problem.new_soft_constraint(:c) {|c| % 4 == 0}
problem.new_soft_constraint(:d) {|d| % 5 == 0}
 
puts problem.backtrack
