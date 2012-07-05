# This module represents the ability to store and reason about performance
# metrics using multi-attribute utility theory.
#
# TODO: At the moment this is only additive. Extend it to contain arbitrary
# utility functions.

module Multi_attribute_utility

  # This is an array indexed by node_id which tells you the most recent
  # (instantaneous) utility gained by this node from the node with the given id.
  attr_reader :last_node_utilities


  # This is an array indexed by node_id which tells you the cumulative (over
  # time) utility gained by this node from the node with the given id.
  attr_reader :total_node_utilities

  def initialize_multi_attribute_utility
    # Keep track of the utilities of different items, for example nodes in a
    # network, or product types bought and sold.
    #
    # TODO rename to something more generic!
    @last_node_utilities = {}
    @total_node_utilities = {}

    # Utility weights for attributes of items in the additive utility function.
    @weights = { :beta => 0.5, :gamma => 0.5 }
  end


  def utility values
    @weights[:beta] * values[:beta] - @weights[:gamma] * values[:gamma]
  end


  # The total instantaneous conjoint utility accumulated by this node
  # from all items (e.g. all other nodes).
  def last_conjoint_utility
    # @total_node_utilities is a hash with the key being the item's id (e.g.
    # node_id) and the value being the associated utility value. So, we just
    # need to sum the values.
    (@last_node_utilities.values.inject(:+) or 0)
  end

  # Return the total cumulative conjoint utility so far accumulated by this
  # node.
  def cumulative_conjoint_utility
    # @total_node_utilities is a hash with the key being the item's id (e.g.
    # node_id) and the value being the associated utility value. So, we just
    # need to sum the values.
    (@total_node_utilities.values.inject(:+) or 0)
  end



  # Messages this capability responds to


  def update_benefits_and_costs benefits_and_costs

    # Need to update every item's last utility to what's in here or zero.
    # Might need to add new items, if they are new in here.

    # First, update value for last time step or zero:
    @last_node_utilities.each do |item_id, utility_value|
      if benefits_and_costs[item_id]
        @last_node_utilities[item_id] = utility benefits_and_costs[item_id]
      else
        @last_node_utilities[item_id] = 0
      end
    end

    # Second, add any new items from benefits_and_costs to our item lists:
    benefits_and_costs.each do |item_id, attribute_values|
      unless @last_node_utilities[item_id]
        @last_node_utilities[item_id] = utility benefits_and_costs[item_id]
      end
    end

    # Finally, update our running totals...
    @last_node_utilities.each do |item_id, utility_value|
      if @total_node_utilities[item_id]
        @total_node_utilities[item_id] += utility_value
      else
        @total_node_utilities[item_id] = utility_value
      end
    end

  end

end
