require "set"
require "neighbourhood-selection/base_selection_strategies"
require "neighbourhood-selection/bandit_meta_strategies"
require "neighbourhood-selection/ensemble_meta_strategies"


class Node

  # Mix in the basic strategies: broadcast, smooth and step
  include Base_Selection_Strategies
  include Ensemble_Meta_Strategies
  include Bandit_Meta_Strategies


  attr_reader :node_id
  attr_reader :taus

  # Should this node output debugging info?
  attr_reader :debug

  def initialize id, communication_strategy, connected, debug=false
    @possible_nodes = {}
    @taus = {}
    @last_node_utilities = {}
    @total_node_utilities = {}
    @node_id = id
    @random = Random.new @node_id
    @debug = debug
    @connected = connected

    # Pheromone parameters
    @initial_tau = 1.0
    @evaporation_rate = 0.01
    @delta = 1

    # Utility parameters
    @weights = { :beta => 0.5, :gamma => 0.5 }

    # The communication strategy is set in the configuration and passed in.
    @communication_strategy = communication_strategy

    if debug?
      print "Node #{@node_id} created: "
      p self
      puts
    end

  end


  # This provides the first part of a node's behaviour during one timestep.
  # The method receives a list of the possible nodes, with which this node could
  # communicate. It updates its local knowledge of that and selects the relevant
  # neighbourhood from them. It returns this selected relevant neighbourhood.
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

  # Select and return the relevant neighbourhood.
  #
  # The strategy currently in @communication_strategy must exist as a method.
  def select_relevant_neighbourhood
    begin
      method(@communication_strategy).call
    rescue => e
      warn "Warning: The neighbourhood selection strategy generated an exception of type #{e.class}."
      warn "--> #{e}"
      warn "--> This node will select *no nodes*."
      Set.new
    end
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


  # Is this node connected to the network, or not?
  def is_connected?
    @connected
  end

  def connect
    @connected = true
  end
  
  def disconnect
    @connected = false
  end


  # Should this node output debugging info?
  def debug?
    @debug
  end


end
