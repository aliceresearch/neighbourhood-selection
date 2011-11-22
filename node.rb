require "set"

class Node
  
  attr_reader :node_id  
    
  def initialize id
    @taus = {}
    @node_id = id
  end
  
  def step1 possible_nodes
    @taus.keep_if { |i, t|
      possible_nodes.find { |n| n.node_id == i } 
    }
    
    possible_nodes.each { |b|
      if !@taus[b.node_id]
        @taus[b.node_id] = 1.0
      end
    }
    
    relevant_neighbourhood = select_relevant_neighbourhood_from possible_nodes
  end

  def step2 benefits_and_costs
    benefits_and_costs.each { |i, values| 
      puts "node_id #{i} benefits_and_costs #{values.inspect}"
    }
  end

  def print_taus
    @taus.each { |i,t|
      puts "node_id #{i} tau #{t}" 
    }
  end
  
  def select_relevant_neighbourhood_from possible_nodes
    possible_nodes
  end 

end
    