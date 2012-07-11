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
  # You also have access to all present self-awareness information.
  # This is accessed by retrieving it from the self-awareness engine, as
  # follows:
  #
  # self.awareness.retrieve(:knowledge)
  #
  # where "knowledge" is the name of the API method provided by a self-awareness
  # capability.
  #
  # Bear in mind that this self-awareness capability may not have been enabled,
  # so it's best to check that this returns something, rather than nil. 
  #
  # For example, to ask the self-awareness engine for the last conjoint utility
  # value (a performance metric defined in the multi_attribute_utility
  # capability), do this:
  #
  # x = self.awareness.retrieve(:last_conjoint_utility)
  #
  # Other self-knowledge items include taus and possible_nodes. Take a look in
  # the relevant self-awareness capability modules for a complete list.
  #
  #
  # Other things you have access to:
  #
  #  self.random
  #    This method returns an object of type Random. You should use it for ALL
  #    your random number generating needs. Typically, get a random number by
  #    calling self.random.rand(max). In order to ensure that experiments are
  #    repeatable, do not get random numbers any other way!
  #
  #  self.debug?
  #    This is a method that returns a boolean and tells you whether or not the
  #    user wants to see debugging output. You should check if it is true before
  #    outputting anything. You might want to use the method
  #    print_selected_nodes to give helpful debugging output, as shown in the
  #    example.



  # This is a simple example meta-strategy.
  def meta_bandit_example

    # Here is a simple example, which uses the broadcast strategy 50% of the
    # time, and the smooth strategy the other 50% of the time, chosen at random.
    if self.random.rand < 0.5
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
  def meta_bandit_epsilon_greedy

    # Default parameters - in case nothing was given in @strategy_parameters
    meta_bandit_epsilon = (@strategy_parameters[:meta_bandit_epsilon] or 0.01)

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
      @strategies = { broadcast: {count: 0, payoff: self.random.rand / 1000000},
                      smooth: {count: 0, payoff: self.random.rand / 1000000},
                      step: {count: 0, payoff: self.random.rand / 1000000},
                      ucb1: {count: 0, payoff: self.random.rand / 1000000},
                      adaptive_pursuit: {count: 0, payoff: self.random.rand / 1000000},
                      epsilon_greedy: {count: 0, payoff: self.random.rand / 1000000}
                    }
    else
      # Check what we used last time, and update our knowledge based on its
      # performance.
      unless @last_used_strategy
        raise "Error: Bandit strategy had no information on previously chosen strategy."
      else
        @strategies[@last_used_strategy][:count] += 1
        @strategies[@last_used_strategy][:payoff] += self.awareness.retrieve(:last_conjoint_utility)

        if debug?
          puts "Added utility of #{self.awareness.retrieve(:last_conjoint_utility)} to #{@last_used_strategy}"
        end

      end

    end

    # With probability 1-epsilon, we select the best known strategy so far 
    if self.random.rand > meta_bandit_epsilon
      # This will only return one strategy, even in the event of ties. See the
      # above comment for an explanation of how this is mitigated.
      #
      # max_by returns an array of the form [key, value], so we take [0] to get
      # just a symbol for the selected strategy.
      selected_strategy = @strategies.max_by { |k, v| v[:payoff]/v[:count] }[0]
    else
      # Select a strategy at random from the list
      selected_strategy = @strategies.keys.sample(random: self.random)
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
