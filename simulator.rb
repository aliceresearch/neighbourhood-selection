require "set"
require "./node"
require "./gamma"

class Simulator

  attr_reader :nodes

  DEBUG = false

  # Create a new Simulator object and associated requirements. At present this
  # creates a new set of nodes (6 by default; this can be overridden by passing
  # in the number of nodes to create).
  #
  # TODO: Make this read in the simulation configuration from a file, especially
  # node_parameters.
  #
  def initialize numnodes = 6
    @nodes = Set.new
    populateNodes numnodes
    @random = Random.new 1337
    @gamma = Gamma.new @random

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

  # Populate the @nodes object with n new nodes, indexed incrementally from 0.
  #
  def populateNodes n
    n.times { |i|
      @nodes.add Node.new i
    }

  end


  # Produce and return a sampled benefit and cost from the edge a -> b.
  # The benefit and cost are determined by the implementation of
  # benefit_generator.
  #
  def get_benefits_and_costs a, b

    # The parameters for this edge:
    p = @node_parameters[a][b][:p]
    alpha = @node_parameters[a][b][:alpha]
    theta = @node_parameters[a][b][:theta]

    # The attribute hash to return:
    { :beta => (benefit_generator p, alpha, theta), :gamma => cost_generator }
  end


  # This method is called internally by get_benefits_and_costs. It calls the
  # constituent randomised components.
  # In this case, they are a Bernoulli and gamma process, with parameters for
  # each edge as specified in @node_parameters.
  #
  def benefit_generator p, alpha, theta
    (bernoulli_generator p) * (@gamma.gamma_variate alpha, theta)
  end

  # This method is called internally by get_benefits_and_costs. At present it
  # returns 1, since we assume that costs are constant.
  def cost_generator
    1
  end

  # A simple Bernoulli generator. Returns 1 with probability p, 0 otherwise.
  #
  # TODO: Separate this out into a library.
  #
  def bernoulli_generator p
    if @random.rand < p
      1
    else
      0
    end
  end


  # Run one discrete time step of the simulation.
  # This iterates through each node, running their step1 and step2 methods.
  # Typically, this means they set their relevant neighbourhood based on
  # previous knowledge (e.g. tau values), communicate and sample benefits and
  # costs. They then update their tau values accordingly.
  #
  def step
    @nodes.each do |node|

      # Step 1 asks the node for its chosen relevant neighbourhood, which it is
      # responsible for determining based on its prior knowledge (e.g. tau
      # values).
      #
      # In order to do this, we give the node the set of possible nodes it
      # could communicate with and receive back a subset of these.
      neighbourhood = node.step1 @nodes.find_all { |n| n.node_id != node.node_id}

      # Next we determine the benefit and cost associated with each edge in the
      # relevant neighbourhood of the node.
      benefits_and_costs = { }
      neighbourhood.each do |neighbour|
        benefits_and_costs[neighbour.node_id] =
          get_benefits_and_costs node.node_id, neighbour.node_id
      end

      # In step 2, we tell the node what the benefits and costs were, so that it
      # can update its knowledge of each node (e.g. tau values).
      node.step2 benefits_and_costs

    end

    # Finally, we yield to a block which may have been passed in to the step
    # method. This can be used for printing out or otherwise collecting
    # information about the state of the simulation at the end of the time
    # step.
    yield

  end

end
