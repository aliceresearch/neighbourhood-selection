module Network_Cumulative_Relaxed_Rewards

  # The cumulative reward recorded for the node with ID node_id.
  attr_reader :cumulative_relaxed_rewards


  def initialize_network_cumulative_relaxed_rewards

    # This is an array, indexed by Node.node_id, which contains the current sum of
    # rewards associated with each node (indexed by the given node_id).
    @cumulative_relaxed_rewards = {}

    # The "amount of relaxation"
    @alpha = 0.01

  end

  # This capability responds to two messages:
  # - when the neighbourhood of possible nodes is updated,
  # - when the benefits and costs of interaction are received.


  # Clean out unneeded sum values for disappeared nodes
  # and create default sum values for new nodes
  def update_neighbourhood new_neighbourhood
    @cumulative_relaxed_rewards.keep_if do |i, t|
      new_neighbourhood.find { |n| n.node_id == i }
    end

    new_neighbourhood.each do |b|
      if !@cumulative_relaxed_rewards[b.node_id]
        @cumulative_relaxed_rewards[b.node_id] = 0
      end
    end
  end


  # Update the cumulative reward values for each node,
  # based on the benefits and costs.
  def update_benefits_and_costs benefits_and_costs

    benefits_and_costs.each do |i, values|
      @cumulative_relaxed_rewards[i] =
        (1 - @alpha) * @cumulative_relaxed_rewards[i] +
        @alpha * self.awareness.retrieve(:last_node_utilities)[i]
    end

  end


end
