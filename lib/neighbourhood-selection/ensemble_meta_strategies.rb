module Ensemble_Meta_Strategies

  # Define a method here for each strategy you want to expose to the simulation.
  # The strategy will be known by the name of the method, which can then be
  # specified in the simulation.yml configuration file.
  #
  #
  # You can make use of the following base selections strategy methods:
  #   broadcast
  #   smooth
  #   step
  #
  # Each one will return a Set containing the nodes selected by that strategy,
  # given the current knowledge of the node.
  #
  # Other things you have access to:
  #
  #  @possible_nodes
  #    This is a Set of all the possible Nodes to choose from.  This may change
  #    between method calls, if the network topology changes, for example.
  #
  #  @taus
  #    This is an array, indexed by Node.node_id, which contains the current tau
  #    value (i.e. pheromone level) on the link between this node and the node
  #    with the given node_id. These values will almost certainly regularly
  #    change, including based on your actions.
  #
  #  @random
  #    This is an object of type Random. You should use it for ALL your random
  #    number generating needs. Typically, get a random number by calling
  #    @random.rand(max). In order to ensure that experiments are repeatable, do
  #    not get random numbers any other way!
  #
  #  debug?
  #    This is a method that returns a boolean and tells you whether or not the
  #    user wants to see debugging output. You should check if it is true before
  #    outputting anything. You might want to use the method
  #    print_selected_nodes to give helpful debugging output, as shown in the
  #    example.
  #
  #

  # This is a simple example meta-strategy.
  def ensemble_example

    # Here is a simple example, which uses the broadcast strategy 50% of the
    # time, and the smooth strategy the other 50% of the time, chosen at random.
    if @random.rand < 0.5
      selected_nodes = broadcast
    else
      selected_nodes = smooth
    end

    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end

end
