require "set"
require "./node"

class Simulator
  
  attr_reader :nodes
  
  def initialize numnodes = 6
    @nodes = Set.new
    populateNodes numnodes
    @random = Random.new 1337
  end
  
  def populateNodes n
    n.times { |i|
      @nodes.add Node.new i
    }
    
  end
  
  def benefit_generator p, alpha, theta
    (bernoulli_generator p) * (gamma_generator alpha, theta)
  end
  
  def bernoulli_generator p
    if @random.rand < p
      1 
    else 
      0 
    end
  end
  
  def gamma_generator alpha, theta
    1
  end

  def step 
    @nodes.each { |node| 
      neighbourhood = node.step1 @nodes.find_all { |n| n.node_id != node.node_id}

      benefits_and_costs = { }
      neighbourhood.each { |neighbour| 
        benefits_and_costs[neighbour.node_id] = { :beta => 1, :gamma => 1 }
      }
      node.step2 benefits_and_costs
    }
    @nodes.find { |n| n.node_id==0 }.print_taus
  end

end