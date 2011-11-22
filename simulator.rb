class Simulator
  
  attr_reader :nodes
  
  def initialize(numnodes = 5)
    @nodes = Array.new
    
    populateNodes numnodes
  end
  
  def populateNodes(n)
    n.times {@nodes.add 1}
  end

end