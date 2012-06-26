module Bandit_Meta_Strategies

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
  #  @last_node_utilities
  #    This is an array indexed by node_id which tells you the most recent
  #    (instantaneous) utility gained by this node from the node with the given
  #    id.
  #
  #  @total_node_utilities
  #    This is an array indexed by node_id which tells you the cumulative (over
  #    time) utility gained by this node from the node with the given id.
  #
  #  last_conjoint_utility
  #    A method which returns the total instantaneous conjoint utility
  #    accumulated by this node from all other nodes.
  #
  #  cumulative_conjoint_utility
  #     A method which returns the total cumulative conjoint utility so far
  #     accumulated by this node.

  # This is a simple example meta-strategy.
  def bandit_example

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


  # Basic epsilon greedy bandit solving strategy
  def bandit_epsilon_greedy epsilon=0.1

    # We need to keep track of the learnt expected payoff from each arm
    # (strategy), along with the number of times we used it.
    #
    # To reduce the amount of data stored, but also to try to maintain accuracy,
    # we store the total payoff from each strategy so far, plus the number of
    # times it has been used. This has the disadvantage that the averages have
    # to be calculated on the fly, but we don't lose precision and also don't
    # have to store every data point.
    # 
    # To simplify the implementation, when finding the best known strategy
    # below, we break any ties by just selecting the first strategy in the tie
    # (this is max_by's default behaviour). Therefore, as suggested in Sutton
    # and Barto's book, we initialise the average payoffs to very
    # small random numbers (instead of zero) to avoid an initial bias based on
    # the ordering of the strategies in this hash.
    #
    unless @strategies
      # Initialise, when we are starting up and have no information.
      @strategies = { broadcast: {count: 0, payoff: @random.rand / 1000000},
                      smooth: {count: 0, payoff: @random.rand / 1000000},
                      step: {count: 0, payoff: @random.rand / 1000000}
                    }
    else
      # Check what we used last time, and update our knowledge based on its
      # performance.
      unless @last_used_strategy
        raise "Error: Bandit strategy had no information on previously chosen strategy."
      else
        @strategies[@last_used_strategy][:count] += 1
        @strategies[@last_used_strategy][:payoff] += last_conjoint_utility

        if debug?
          puts "Added utility of #{last_conjoint_utility} to #{@last_used_strategy}"
        end

      end

    end

    # With probability 1-epsilon, we select the best known strategy so far 
    if @random.rand > epsilon
      # This will only return one strategy, even in the event of ties. See the
      # above comment for an explanation of how this is mitigated.
      #
      # max_by returns an array of the form [key, value], so we take [0] to get
      # just a symbol for the selected strategy.
      selected_strategy = @strategies.max_by { |k, v| v[:payoff]/v[:count] }[0]
    else
      # Select a strategy at random from the list
      selected_strategy = @strategies.keys.sample(random: @random)
    end

    # Get the set of selected nodes from the selected strategy.
    selected_nodes = self.method(selected_strategy).call

    # Record that we used this strategy last.
    @last_used_strategy = selected_strategy
    

    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      puts "Used #{selected_strategy} strategy."
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end

end
