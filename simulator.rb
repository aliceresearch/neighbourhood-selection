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
      neighbourhood = node.step1 @nodes.find_all { |n| n != node}
      puts "neighbourhood:"
      puts neighbourhood.inspect
      puts "--------------"
    }
  end

end