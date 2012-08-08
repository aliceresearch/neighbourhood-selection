module Bandit_Selection_Strategies

  def ucb1

    # Keep track of the number of times we picked each arm
    unless @selected_count
      @selected_count = Hash.new(0)
    end

    # Keep track of the number of times we didn't pick each arm
    # (and did nothing instead)
    unless @unselected_count
      @unselected_count = Hash.new(0)
    end

    selected_nodes = Set.new

    # Compare each node as an arm against a phantom arm of inaction.
    self.awareness.retrieve(:possible_nodes).each do |node|

      # Initialisation phase: test each alternative once.

      if @selected_count[node.node_id] == 0
        selected_nodes.add node
        @selected_count[node.node_id] +=1
        next
      end

      if @unselected_count[node.node_id] == 0
        @unselected_count[node.node_id] += 1
        next
      end


      # Iterative phase: choose highest ucb value

      average_node_reward = self.awareness.retrieve(:cumulative_rewards)[node.node_id] /
        @selected_count[node.node_id]

      total_actions = @selected_count[node.node_id] + @unselected_count[node.node_id]

      node_ucb = average_node_reward +
        Math.sqrt((2 * Math.log(total_actions)) / @selected_count[node.node_id])

      inaction_ucb = 0 +
        Math.sqrt((2 * Math.log(total_actions)) / @unselected_count[node.node_id])

      if debug?
        print "node #{node.node_id}: node_ucb = #{node_ucb}, inaction_ucb = #{inaction_ucb}."
      end

      # Add this node if its index is greater than the inaction index.
      if node_ucb > inaction_ucb
        selected_nodes.add(node)
        @selected_count[node.node_id] +=1
        if debug?
          puts " -- SELECTED"
        end
      else
        @unselected_count[node.node_id] +=1
        if debug?
          puts " Not selected"
        end
      end

    end


    # Bit of debugging output
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes
  end


  def epsilon_greedy

    # Default parameters - in case nothing was given in @strategy_parameters
    bandit_epsilon = (@strategy_parameters[:bandit_epsilon] or 0.01)

    # Keep track of the number of times we included each node
    unless @selected_count
      @selected_count = Hash.new(0)
    end

    selected_nodes = Set.new

    # Compare each node as an arm against a phantom arm of inaction.
    self.awareness.retrieve(:possible_nodes).each do |node|

      # Initialisation phase: test this arm once.

      if @selected_count[node.node_id] == 0
        selected_nodes.add node
        @selected_count[node.node_id] +=1
        next
      end

      # We don't need to test the phantom arm, since its reward is always 0.

      # Iterative phase:

      average_node_reward = self.awareness.retrieve(:cumulative_rewards)[node.node_id] /
        @selected_count[node.node_id]

      # With probability 1-epsilon, we select the best known strategy so far 
      if self.random.rand > bandit_epsilon

        # Assume inaction gives a zero reward:
        if average_node_reward > 0
          selected_nodes.add node
          @selected_count[node.node_id] += 1
          if debug?
            puts " -- CHOSE BEST STRATEGY: SELECTED"
          end
        else
          if debug?
            puts " -- CHOSE BEST STRATEGY: NOT SELECTED"
          end
        end

      else

        # Select a strategy at random from the list
        if self.random.rand > 0.5
          selected_nodes.add node
          @selected_count[node.node_id] += 1
          if debug?
            puts " -- SELECTED AT RANDOM"
          end
        else
          if debug?
            puts " -- NOT SELECTED AT RANDOM"
          end
        end

      end

    end

    # Return our final set
    selected_nodes

  end


  def relaxed_epsilon_greedy

    # Default parameters - in case nothing was given in @strategy_parameters
    relaxed_bandit_epsilon = (@strategy_parameters[:relaxed_bandit_epsilon] or 0.01)

    ## Keep track of the number of times we included each node
    #unless @selected_count
      #@selected_count = Hash.new(0)
    #end

    selected_nodes = Set.new

    # Compare each node as an arm against a phantom arm of inaction.
    self.awareness.retrieve(:possible_nodes).each do |node|

      # With probability 1-epsilon, we select the best known strategy so far 
      if self.random.rand > relaxed_bandit_epsilon

        # Assume inaction gives a zero reward:
        if self.awareness.retrieve(:cumulative_relaxed_rewards)[node.node_id] >= 0
          selected_nodes.add node
          if debug?
            puts " -- CHOSE BEST STRATEGY: SELECTED"
          end
        else
          if debug?
            puts " -- CHOSE BEST STRATEGY: NOT SELECTED"
          end
        end

      else

        # Select a strategy at random from the list
        if self.random.rand > 0.5
          selected_nodes.add node
          if debug?
            puts " -- SELECTED AT RANDOM"
          end
        else
          if debug?
            puts " -- NOT SELECTED AT RANDOM"
          end
        end

      end

    end

    # Return our final set
    selected_nodes

  end



  #def probability_matching p_min=0.01

    #selected_nodes = Set.new

    ## Compare each node as an arm against a phantom arm of inaction.
    #self.awareness.retrieve(:possible_nodes).each do |node|

      ## Probability of choosing to include the node - in the two arm case when
      ## one arm's average reward is always 0, this collapses down to the
      ## following:
      #s = p_min + (1 - (2 * p_min))

      ## I don't understand this - how is it supposed to work with rewards that
      ## can be negative?


    #end

  #end

  def adaptive_pursuit p_min=0.1, beta=0.1

    unless @adaptive_pursuit_node_probabilities
      @adaptive_pursuit_node_probabilities = Hash.new(0.5)
      @adaptive_pursuit_inaction_probabilities = Hash.new(0.5)
      @init = true
    end

    # Calculated static value
    p_max = 1 - p_min

    selected_nodes = Set.new

    # Compare each node as an arm against a phantom arm of inaction.
    self.awareness.retrieve(:possible_nodes).each do |node|

      # Initialisation phase: test this arm once.

      if @init
        selected_nodes.add node
        next
      end

      # Iterative phase:

      # Select the node based on the current probabilities:
      if self.random.rand < @adaptive_pursuit_node_probabilities[node.node_id]
        selected_nodes.add node
      end

      # Update probabilities for next time
      if (self.awareness.retrieve(:cumulative_relaxed_rewards)[node.node_id] > 0)

        @adaptive_pursuit_node_probabilities[node.node_id] +=
          beta * (p_max - @adaptive_pursuit_node_probabilities[node.node_id])

        @adaptive_pursuit_inaction_probabilities[node.node_id] +=
          beta * (p_min - @adaptive_pursuit_inaction_probabilities[node.node_id])

      else

        @adaptive_pursuit_inaction_probabilities[node.node_id] +=
          beta * (p_max - @adaptive_pursuit_inaction_probabilities[node.node_id])

        @adaptive_pursuit_node_probabilities[node.node_id] +=
          beta * (p_min - @adaptive_pursuit_node_probabilities[node.node_id])

      end
    end

    # Don't initialise next time
    @init = false

    # Return our nodes
    selected_nodes
  end

end
