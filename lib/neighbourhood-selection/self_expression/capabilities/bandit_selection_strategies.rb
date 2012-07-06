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

end
