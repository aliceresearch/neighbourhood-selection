require "set"
require "./node"

class Simulator
  
  attr_reader :nodes
  
  def initialize(numnodes = 6)
    @nodes = Set.new
    
    populateNodes numnodes
  end
  
  def populateNodes(n)
    n.times { |i|
      @nodes.add Node.new i
    }
    
  end

  def step 
    @nodes.each { |node| 
      neighbourhood = node.step1 @nodes.find_all { |n| n.node_id != node.node_id}
      puts "neighbourhood:"
      puts neighbourhood.inspect
      puts "--------------"

      benefits_and_costs = { }
      neighbourhood.each { |neighbour| 
        benefits_and_costs[neighbour.node_id] = { :beta => 4, :gamma => 1 }
      }
      node.step2 benefits_and_costs
    }
  end

end