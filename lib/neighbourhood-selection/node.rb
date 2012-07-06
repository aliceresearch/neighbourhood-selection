require "set"

# Self-awareness engines
require "neighbourhood-selection/self_awareness/self_awareness_engine"

# Self-expression engine
require "neighbourhood-selection/self_expression/self_expression_engine"


class Node

  attr_reader :node_id

  # Should this node output debugging info?
  attr_reader :debug

  def initialize id, communication_strategy, connected, debug=false

    # Basic node information and capabilities.
    @node_id = id
    @random = Random.new @node_id
    @debug = debug
    @connected = connected

    # Create this node's self-awareness engine.
    @self_awareness = Self_Awareness_Engine.new(@random, debug?)

    # Enable capabilities in the self-awareness engine.
    #
    # The order of capabilities matters! Specifically, they will receive
    # messages in the order in which they are enabled. For example, if you rely
    # on some updated model in one capability for use in another, for the model
    # to be up to date when accessed, the capability that updates the model
    # should precede the capability which uses it.
    #
    # TODO: This should be configurable from config files, as
    # communication_strategy is.
    @self_awareness.enable_capability :Multi_attribute_utility
    @self_awareness.enable_capability :Network
    @self_awareness.enable_capability :Network_Pheromones
    @self_awareness.enable_capability :Network_Cumulative_Rewards

    # The self-expression engines that this node uses.
    # This is a hash of engine objects.
    # TODO: Engines should be registered through methods.
    @self_expression = Self_Expression_Engine.new(@random, debug?)

    # Tell the self-expression engine where it can look for its self-awareness
    # information, i.e. the self-awareness engine.
    @self_expression.set_self_awareness_source @self_awareness

    # Enable capabilities of the self-expression engine.
    @self_expression.enable_capability "Base_Selection_Strategies"
    @self_expression.enable_capability "Bandit_Selection_Strategies"
    @self_expression.enable_capability "Ensemble_Meta_Strategies"
    @self_expression.enable_capability "Bandit_Meta_Strategies"

    # Set the actual strategy, from those capabilities enabled, to use.
    @self_expression.set_strategy communication_strategy

    if debug?
      print "Node #{@node_id} created: "
      p self
      puts
    end

  end


  # The remainder of the node class is concerned with how to deal with incoming
  # messages (from the simulator in this case).
  #
  # For convenience in this simulation, these are named in the order in which
  # the messages are received in a simulation time step.

  # The first of these messages is an update of the node's connectivity, which
  # is the first message received during one timestep.
  # The method receives a list of the possible nodes, with which this node could
  # communicate. It passes this information to the self-awareness engine(s),
  # which update the local knowledge.
  # 
  # It then calls the self-expression engine to select the relevant
  # neighbourhood. It returns this selected relevant neighbourhood back to the
  # simulator.

  def update_neighbourhood new_possible_nodes

    # Pass on this message to the self-awareness engine.
    @self_awareness.notify __method__, new_possible_nodes

    # TODO: In an asynchronous framework, this would represent a notification
    # (as we do in the framework through redis) to the "self-expression engine",
    # that something has changed an might need acting upon. Whether it does is
    # up to the self-expression engine. In this case, the self-expression engine
    # would do the communicating, not just the selecting, and we would have a
    # similar construct to the one above for self-awareness engines.
    # 
    # We would pass the hash of self-awareness engines as a parameter
    # (reference) to the self-expression engine(s), to do what it needs to.

    # However, in this synchronous simulator, we know that this method must
    # return a set of selected nodes, so we do the following.
    relevant_neighbourhood =
      @self_expression.select_relevant_neighbourhood

  end


  # This is the second message type received by the node. Again we send the
  # information received to the self-awareness engine(s) to update our
  # knowledge, e.g. the pheromone values, based on the benefits and costs
  # derived.
  def update_benefits_and_costs benefits_and_costs

    # Pass on this message to the self-awareness engine.
    @self_awareness.notify __method__, benefits_and_costs

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
    @self_awareness.retrieve(:taus).each { |i,t|
      # puts "node_id #{i} tau #{t}"
      destination.print " #{t}"
    }
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
    @self_awareness.retrieve(:total_node_utilities).each { |i,u|
      # puts "node_id #{i} tau #{u}"
      destination.print " #{u}"
    }
  end


  # Print the total cumulative conjoint utility so far accumulated by this node.
  #
  # Optionally, specify a file object to print to as a parameter. If none is
  # given, output goes to STDOUT.
  #
  def print_cumulative_conjoint_utility destination=STDOUT
    destination.print @self_awareness.retrieve(:cumulative_conjoint_utility)
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
  #
  # TODO: Is this an underlying fact, or does it belong in the network
  # self-awareness capability module?
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
