module Base_Selection_Strategies


  def broadcast
    selected_nodes = Set.new @possible_nodes

    # Bit of debugging output
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes
  end


  def smooth
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


  def step

    # Default parameters - should probably set these in the configuration files.
    @step_epsilon = 0.95
    @step_eta = 0.01

    selected_nodes = Set.new
    @possible_nodes.each {|n|
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

end
