require "set"

class Node
  
  attr_reader :node_id  
    
  def initialize(id)
    @taus = {}
    @node_id = id
  end
  
  def step1(possible_nodes)
    @taus.keep_if { |i, t|
      possible_nodes.find { |n| n.node_id == i } 
    }
    
    possible_nodes.each { |b|
      if !@taus[b.node_id]
        @taus[b.node_id] = 1.0
      end
    }
  end

  def print_taus
    @taus.each { |i,t|
      puts "node_id #{i} tau #{t}" 
    }
  end

end
    