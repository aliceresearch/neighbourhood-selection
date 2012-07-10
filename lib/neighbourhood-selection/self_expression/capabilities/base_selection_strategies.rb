module Base_Selection_Strategies

  def broadcast
    # To access self-awareness knowledge, pass the requested method name to
    # self.awareness:
    selected_nodes = Set.new self.awareness.retrieve(:possible_nodes)

    # Bit of debugging output
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes
  end


  def smooth
    selected_nodes = Set.new
    max_tau = self.awareness.retrieve(:taus).values.max
    self.awareness.retrieve(:possible_nodes).each {|n|
      p = (1 + self.awareness.retrieve(:taus)[n.node_id])/max_tau
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


  def step

    # Default parameters - in case nothing was given in @strategy_parameters
    step_epsilon = (@strategy_parameters[:step_epsilon] or 0.95)
    step_eta = (@strategy_parameters[:step_eta] or 0.001)

    selected_nodes = Set.new
    self.awareness.retrieve(:possible_nodes).each {|n|
      if self.awareness.retrieve(:taus)[n.node_id] > step_epsilon
        selected_nodes.add n
      else
        if @random.rand < step_eta
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

end
