require "set"
require "./node"

class Simulator
  
  attr_reader :nodes
  
  
  def initialize numnodes = 6
    @nodes = Set.new
    populateNodes numnodes
    @random = Random.new 1337
    
    @node_parameters = 
      { 0 => {
        1 => { :p => 1, :alpha => 1, :theta => 0.5 },
        2 => { :p => 0.5, :alpha => 1, :theta => 0.5 },
        3 => { :p => 0.1, :alpha => 1, :theta => 0.5 },
        4 => { :p => 0.1, :alpha => 1, :theta => 0.5 },
        5 => { :p => 0.1, :alpha => 1, :theta => 0.5 } }, 
       
      1 => {
        0 => { :p => 1, :alpha => 1, :theta => 0.5 },
        2 => { :p => 1, :alpha => 1, :theta => 0.5 },
        3 => { :p => 1, :alpha => 1, :theta => 0.5 },
        4 => { :p => 1, :alpha => 1, :theta => 0.5 },
        5 => { :p => 1, :alpha => 1, :theta => 0.5 } },
        
      2 => {
        0 => { :p => 1, :alpha => 1, :theta => 0.5 },
        1 => { :p => 1, :alpha => 1, :theta => 0.5 },
        3 => { :p => 1, :alpha => 1, :theta => 0.5 },
        4 => { :p => 1, :alpha => 1, :theta => 0.5 },
        5 => { :p => 1, :alpha => 1, :theta => 0.5 } },
        
      3 => {
        0 => { :p => 1, :alpha => 1, :theta => 0.5 },
        1 => { :p => 1, :alpha => 1, :theta => 0.5 },
        2 => { :p => 1, :alpha => 1, :theta => 0.5 },
        4 => { :p => 1, :alpha => 1, :theta => 0.5 },
        5 => { :p => 1, :alpha => 1, :theta => 0.5 } },
    
    
      4 => {
        0 => { :p => 1, :alpha => 1, :theta => 0.5 },
        1 => { :p => 1, :alpha => 1, :theta => 0.5 },
        2 => { :p => 1, :alpha => 1, :theta => 0.5 },
        3 => { :p => 1, :alpha => 1, :theta => 0.5 },
        5 => { :p => 1, :alpha => 1, :theta => 0.5 } },
    
    
      5 => {
        0 => { :p => 1, :alpha => 1, :theta => 0.5 },
        1 => { :p => 1, :alpha => 1, :theta => 0.5 },
        2 => { :p => 1, :alpha => 1, :theta => 0.5 },
        3 => { :p => 1, :alpha => 1, :theta => 0.5 },
        4 => { :p => 1, :alpha => 1, :theta => 0.5 } } }
    
    
    
  end
  
  def populateNodes n
    n.times { |i|
      @nodes.add Node.new i
    }
    
  end
  
  def get_benefits_and_costs a, b
    p = @node_parameters[a][b][:p]
    alpha = @node_parameters[a][b][:alpha]
    theta = @node_parameters[a][b][:theta]
    
    { :beta => (benefit_generator p, alpha, theta), :gamma => 1 }
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
    #TODO: Add gamma random number generator
    2
  end

  def step 
    @nodes.each { |node| 
      neighbourhood = node.step1 @nodes.find_all { |n| n.node_id != node.node_id}

      benefits_and_costs = { }
      neighbourhood.each { |neighbour| 
        benefits_and_costs[neighbour.node_id] = 
          get_benefits_and_costs node.node_id, neighbour.node_id
      }
      
      # if node.node_id == 0
      #   puts benefits_and_costs.inspect
      # end
      
      node.step2 benefits_and_costs
    }
    
    @nodes.find { |n| n.node_id==0 }.print_taus
  end

end