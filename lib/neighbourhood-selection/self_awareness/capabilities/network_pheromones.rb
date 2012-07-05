module Network_Pheromones

  # This is an array, indexed by Node.node_id, which contains the current tau
  # value (i.e. pheromone level) on the link between this node and the node
  # with the given node_id. These values will almost certainly regularly
  # change, including based on your actions.
  attr_reader :taus

  # Pheromone parameters
  Initial_tau = 1.0
  Evaporation_rate = 0.01
  Delta = 1


  def initialize_network_pheromones
    @taus = {}
  end

  # This capability responds to two messages:
  # - when the neighbourhood of possible nodes is updated,
  # - when the benefits and costs of interaction are received.


  # Clean out unneeded tau values for disappeared nodes
  # and create default tau values for new nodes
  def update_neighbourhood new_neighbourhood
    @taus.keep_if do |i, t|
      new_neighbourhood.find { |n| n.node_id == i }
    end

    new_neighbourhood.each do |b|
      if !@taus[b.node_id]
        @taus[b.node_id] = Initial_tau
      end
    end
  end


  # Update the tau values, based on the benefits and costs
  def update_benefits_and_costs benefits_and_costs

    # Evaporate all tau values
    # TODO: I'm *sure* there's a nicer rubyish way of doing this
    @taus.each do |i, tau|
      @taus[i] = (1-Evaporation_rate) * @taus[i]
    end

    # Update the tau values based on the observed benefits and costs
    benefits_and_costs.each { |i, values|
      if (self.awareness.retrieve(:last_node_utilities)[i]) > 0
        @taus[i] = @taus[i] + Delta
      end
    }
  end

end
