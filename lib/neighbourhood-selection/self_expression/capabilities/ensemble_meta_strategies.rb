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
  def meta_ensemble_example

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
  

  def meta_ensemble_intersect_smooth_step
    
    selected_nodes = smooth & step    
    
    
    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end


  def meta_ensemble_union_smooth_step
    
    selected_nodes = smooth | step    
    
    
    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end
  

  def meta_ensemble_weighted_sum
    # To do. Right now the result is a union.
    unless @weight_smooth
      @weight_smooth = 0
    end
    
    unless @weight_step
      @weight_step = 0
    end  
    
    selected_nodes = smooth | step    
    
    
    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end
  
  def meta_probabilistic_ensemble_majority_vote
    # Make this compatible with new code.
    selected_nodes = Set.new
    vote_count = Hash.new(0)   # Create an empty hash, with default value for any key 0.

    broadcast_option = self.method(boradcast).call
    smooth_option = self.method(smooth).call
    step_option = self.method(step).call
    
    broadcast_option.each {|n| vote_count[n.node_id] = vote_count[n.node_id] + 1 }
    smooth_option.each {|n| vote_count[n.node_id] = vote_count[n.node_id] + 1 }
    step_option.each {|n| vote_count[n.node_id] = vote_count[n.node_id] + 1 }
    
    self.awareness.retrieve(:possible_nodes).each do |n|
     if @random.rand <= (vote_count[n.node_id]/3.0)
       selected_nodes.add n
     end
    end     
    
    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end

  def meta_weighted_ensemble_majority_vote

    # There is a credit assignment problem that I seem unable to crack for now.
    # So, this meta stragety is the next best thing that came to mind.
    # The credit assignment problem I am talking about is the problem of 
    # assigning credit to individual base strategies given only the ensemble 
    # strategy payoff (which, in our case is the last_conjoint_utility).
    # Could not think of a way to propagate the ensemble strategy payoff back to 
    # individual strategies!
    # 
    # So, this meta strategy does the following:
    # We start with 13 possible ensemble strategies, each defined by a possible 
    # weight distribution over base strategies, e.g. all weights equal, weight 
    # of one higher than the other two, weights of two higher than the third, 
    # and ordering of the three.
    # 
    # Then a 'bandit epsilon greedy strategy' is overlaid on top of these 
    # posible ensemble strategy, and the payoffs of these strategies is updated 
    # based on last_conjoint_utility, whenever selected.
    # 
    # The ensemble strategies that the bandit selects are all probabilistic 
    # majority vote strategies, where the weights over base strategies that 
    # define the ensemble strategy act as 'weighted votes'. The sum of these 
    # weighted votes for a particular node acts as the selection probability 
    # for the node. 
    # 
    # Default parameters - in case nothing was given in @strategy_parameters
    meta_bandit_ensemble_epsilon = (@strategy_parameters[:meta_bandit_ensemble_epsilon] or 0.01)
    
    
    
    unless @strategies
      # Initialise, when we are starting up and have no information.
      @strategies = { all_three: {count: 0, payoff: self.random.rand / 1000000, w_b: 1.0/3.0, w_sm: 1.0/3.0, w_st: 1.0/3.0},
                      broadcast_high: {count: 0, payoff: self.random.rand / 1000000, w_b: 0.9, w_sm: 0.05, w_st: 0.05},
                      smooth_high: {count: 0, payoff: self.random.rand / 1000000, w_b: 0.05, w_sm: 0.9, w_st: 0.05},
                      step_high: {count: 0, payoff: self.random.rand / 1000000, w_b: 0.05, w_sm: 0.05, w_st: 0.9},
                      broadcast_smooth_high: {count: 0, payoff: self.random.rand / 1000000, w_b: 0.45, w_sm: 0.45, w_st: 0.1},
                      broadcast_step_high: {count: 0, payoff: self.random.rand / 1000000, w_b: 0.45, w_sm: 0.1, w_st: 0.45},
                      smooth_step_high: {count: 0, payoff: self.random.rand / 1000000, w_b: 0.1, w_sm: 0.45, w_st: 0.45},
                      order_b_sm_st:{count: 0, payoff: self.random.rand / 1000000, w_b: 0.6, w_sm: 0.3, w_st: 0.1},
                      order_b_st_sm:{count: 0, payoff: self.random.rand / 1000000, w_b: 0.6, w_sm: 0.1, w_st: 0.3},
                      order_sm_b_st:{count: 0, payoff: self.random.rand / 1000000, w_b: 0.3, w_sm: 0.6, w_st: 0.1},
                      order_sm_st_b:{count: 0, payoff: self.random.rand / 1000000, w_b: 0.1, w_sm: 0.6, w_st: 0.3},
                      order_st_b_sm:{count: 0, payoff: self.random.rand / 1000000, w_b: 0.3, w_sm: 0.1, w_st: 0.6},
                      order_st_sm_b:{count: 0, payoff: self.random.rand / 1000000, w_b: 0.1, w_sm: 0.3, w_st: 0.6}
                    }
    else
      unless @last_used_strategy
        raise "Error: Bandit ensemble strategy had no information on previously chosen strategy."
      else
        @strategies[@last_used_strategy][:count] += 1
        @strategies[@last_used_strategy][:payoff] += self.awareness.retrieve(:last_conjoint_utility)

        if debug?
          puts "Added utility of #{self.awareness.retrieve(:last_conjoint_utility)} to #{@last_used_strategy}"
        end

      end
    end
    
    # With probability 1-epsilon, we select the best known strategy so far 
    if self.random.rand > meta_bandit_ensemble_epsilon
      # This will only return one strategy, even in the event of ties.
      #
      # max_by returns an array of the form [key, value], so we take [0] to get
      # just a symbol for the selected strategy.
      selected_strategy = @strategies.max_by { |k, v| v[:payoff]/v[:count] }[0]
    else
      # Select a strategy at random from the list
      selected_strategy = @strategies.keys.sample(random: self.random)
    end

    # Get the set of selected nodes from the selected strategy.
    broadcast_option = self.method(boradcast).call
    smooth_option = self.method(smooth).call
    step_option = self.method(step).call

    selected_nodes = Set.new
    vote_count = Hash.new(0)   # Create an empty hash, with default value for any key 0.

    broadcast_option.each {|n| vote_count[n.node_id] = vote_count[n.node_id] + (@strategies[selected_strategy][:w_b])  }
    smooth_option.each {|n| vote_count[n.node_id] = vote_count[n.node_id] + (@strategies[selected_strategy][:w_sm]) }
    step_option.each {|n| vote_count[n.node_id] = vote_count[n.node_id] + (@strategies[selected_strategy][:w_st]) }
    
    self.awareness.retrieve(:possible_nodes).each do |n|
     if @random.rand <= (vote_count[n.node_id])
       selected_nodes.add n
     end
    end     

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
