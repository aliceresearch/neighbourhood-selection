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
  def ensemble_example

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
  

  def ensemble_intersect_smooth_step
    
    selected_nodes = smooth & step    
    
    
    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end


  def ensemble_union_smooth_step
    
    selected_nodes = smooth | step    
    
    
    # Bit of debugging output - only output for one node, which is the one we
    # are typically interested in.
    if self.debug? and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    # Return the set of selected nodes
    selected_nodes
  end
  

  def ensemble_weighted_sum
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
  

  def ensemble_majority_vote

    #TODO: Fixme
      
    #selected_nodes = Set.new
    
    #vote_count = Array.new(@possible_nodes.size) {|i| 0}
    #broadcast.each {|n|
      #vote_count[n.node_id - 1] = vote_count[n.node_id - 1] + 1
    #}
    
    #smooth.each {|n|
      #vote_count[n.node_id - 1] = vote_count[n.node_id - 1] + 1
    #}
    
    #step.each {|n|
      #vote_count[n.node_id - 1] = vote_count[n.node_id - 1] + 1
    #}
    
    #vote_count.each_index {|id|
      #if vote_count[id] >= 2
        #@possible_nodes.each {|n|
            #if n.node_id == id + 1
              #selected_nodes.add n
        #}
      #end
    #}
    
    
    ## Bit of debugging output - only output for one node, which is the one we
    ## are typically interested in.
    #if self.debug? and @node_id == 0
      #print_selected_nodes 0, selected_nodes
    #end

    ## Return the set of selected nodes
    #selected_nodes
  end

end
