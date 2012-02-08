require "set"

class Node

  attr_reader :node_id
  attr_reader :taus

  # Should this node output debugging info?
  @debug = false
  attr_reader :debug

  def initialize id, debug=false
    @possible_nodes = {}
    @taus = {}
    @last_node_utilities = {}
    @total_node_utilities = {}
    @node_id = id
    @random = Random.new @node_id
    @debug = debug

    # Pheromone parameters
    @initial_tau = 1.0
    @evaporation_rate = 0.01
    @delta = 1

    # Utility parameters
    @weights = { :beta => 0.5, :gamma => 0.5 }

    # Choose one of these three:
    #@communication_strategy = :broadcast
    #@communication_strategy = :smooth
    @communication_strategy = :step

    # Communication strategy parameters:
    #@step_epsilon = 0.95
    #@step_eta = 0.01

    @step_epsilon = 0.95
    @step_eta = 0.01

  end


  def step1 new_possible_nodes
    update_possible_nodes new_possible_nodes

    @taus.keep_if { |i, t|
      @possible_nodes.find { |n| n.node_id == i }
    }

    @possible_nodes.each { |b|
      if !@taus[b.node_id]
        @taus[b.node_id] = @initial_tau
      end
    }

    relevant_neighbourhood = select_relevant_neighbourhood
  end

  # Update the node's knowledge of its possible nodes.
  def update_possible_nodes new_possible_nodes
    @possible_nodes = new_possible_nodes
  end


  # In this step, we update our knowledge, based on the benefits and costs
  # derived.
  def step2 benefits_and_costs

    # Update this iteration's and total utility for each possible node
    @possible_nodes.each do |n|
      if benefits_and_costs[n.node_id] then
        @last_node_utilities[n.node_id] = utility benefits_and_costs[n.node_id]
        if @total_node_utilities[n.node_id]
          @total_node_utilities[n.node_id] += utility benefits_and_costs[n.node_id]
        else
          @total_node_utilities[n.node_id] = utility benefits_and_costs[n.node_id]
        end
      else
        @last_node_utilities[n.node_id] = 0
      end
    end


    # Evaporate all tau values
    @possible_nodes.each { |n|
      @taus[n.node_id]= (1-@evaporation_rate) * @taus[n.node_id]
    }

    # Update the tau values based on the observed benefits and costs
    benefits_and_costs.each { |i, values|
      if (utility values) > 0
        @taus[i] = @taus[i] + @delta
      end
    }
  end

  def utility values
    @weights[:beta] * values[:beta] - @weights[:gamma] * values[:gamma]
  end


  # Print the node ID and the current values in @taus.
  # Formatting is suitable for Gnuplot, Octave or similar.
  # E.g.
  # 0 0.97 0.86 0.51 0.01 0.05
  #
  # Optionally, specify a file object to print to as a parameter. If none is
  # given, output goes to STDOUT.
  #
  def print_taus destination=STDOUT
    destination.print @node_id
    @taus.each { |i,t|
      # puts "node_id #{i} tau #{t}"
      destination.print " #{t}"
    }
    destination.puts
  end

  # Print the node ID and the current utility obtained from each possible node.
  # Formatting is suitable for Gnuplot, Octave or similar.
  # E.g.
  # 0 0.97 0.86 0.51 0.01 0.05
  #
  # Optionally, specify a file object to print to as a parameter. If none is
  # given, output goes to STDOUT.
  #
  def print_total_utilities destination=STDOUT
    destination.print @node_id
    @total_node_utilities.each { |i,u|
      # puts "node_id #{i} tau #{u}"
      destination.print " #{u}"
    }
    destination.puts
  end

  # Return the total cumulative conjoint utility so far accumulated by this
  # node.
  def cumulative_conjoint_utility
    # @total_node_utilities is a hash with the key being the node_id and the
    # value being the associated utility value. So, we just need to sum the
    # values.
    @total_node_utilities.values.inject(:+)
  end

  # Print the total cumulative conjoint utility so far accumulated by this node.
  # The value is put(sed) on its own line.
  #
  # Optionally, specify a file object to print to as a parameter. If none is
  # given, output goes to STDOUT.
  #
  def print_cumulative_conjoint_utility destination=STDOUT
    destination.puts cumulative_conjoint_utility
  end

  def select_relevant_neighbourhood
    case @communication_strategy
      when :broadcast then select_all
      when :smooth then select_smooth
      when :step then select_step
    end
  end

  def select_smooth
    selected_nodes = Set.new
    max_tau = @taus.values.max
    @possible_nodes.each {|n|
      p = (1 + @taus[n.node_id])/max_tau
      if @random.rand < p
        selected_nodes.add n
      end
    }

    # Bit of debugging output
    if debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes
  end

  def select_step
    selected_nodes = Set.new
    @possible_nodes.each {|n|
      # p = (1 + @taus[n.node_id])/max_tau
      if @taus[n.node_id] > @step_epsilon
        selected_nodes.add n
      else
        if @random.rand < @step_eta
          selected_nodes.add n
        end
      end
    }

    # Bit of debugging output
    if debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes

  end

  def select_all
    selected_nodes = Set.new @possible_nodes

    # Bit of debugging output
    if debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes

  end

  def print_selected_nodes id, selected_nodes

    if @node_id == 0
      print "Node #{id} selected:"
      selected_nodes.each { |n|
        print " #{n.node_id}"
      }
      puts
    end

  end

  # Should this node output debugging info?
  def debug?
    @debug
  end


end
