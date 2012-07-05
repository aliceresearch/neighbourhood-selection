module Network

  attr_reader :possible_nodes

  def initialize_network
    @possible_nodes = {}
  end


  # Update the local knowledge of the network's connectivity.
  def update_neighbourhood new_neighbourhood
    @possible_nodes = new_neighbourhood
  end

end
