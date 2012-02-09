require "set"
require "yaml"
require "neighbourhood-selection/util"
require "neighbourhood-selection/node"
require "neighbourhood-selection/gamma"

class Simulator

  attr_reader :nodes

  @debug = false

  # Create a new Simulator object and associated requirements. At present this
  # creates a new set of nodes (6 by default; this can be overridden by passing
  # in the number of nodes to create).
  #
  def initialize sim_name

    # Load simulation scenario specific configuration
    @CONFIG = YAML.load_file("./config/simulation.yml")[sim_name]

    unless @CONFIG
      raise "No configuration found for simulation #{sim_name}."
    end

    # YAML files are parsed with keys as Strings rather than symbols, which we
    # use internally. So, convert the Strings to symbols.
    @CONFIG = Hash.transform_keys_to_symbols(@CONFIG)

    # Should we print debugging output?
    @debug = @CONFIG[:debug]

    # Store the nodes in a set rather than an array or anything else.
    @nodes = Set.new

    # Create the nodes themselves.
    createNodes

    # Create the environment for the nodes, e.g. the network structure.
    createEnvironment

    @random = Random.new 1337
    @gamma = Gamma.new @random

  end

  # Create elements of the environment.
  #
  # An example of this is the values on edges in the network. This method will
  # fill in values not present with default values. If you want this to work,
  # the nodes to fill in for must already have been created (typically by
  # calling createNodes) first.
  #
  def createEnvironment

    # First read in as much information as we have available in the
    # configuration.

    if @CONFIG[:node_parameters]
      @node_parameters = @CONFIG[:node_parameters]
    else
      @node_parameters = {}
    end


    if debug?
      puts "Node parameters read from configuration file:"
      p @node_parameters
    end


    # Then fill in the gaps with default values. This ensures that we don't have
    # to specify a full configuration if we're not interested in parts of it.

    @nodes.each do |source|
      # First ensure there's a record for this node as a source
      unless @node_parameters[source.node_id]
        @node_parameters[source.node_id] = {}
      end

      # Then ensure each record is fully populated - don't create links to
      # oneself though.
      @nodes.each do |dest|
        unless dest.node_id == source.node_id
          unless @node_parameters[source.node_id][dest.node_id]
            @node_parameters[source.node_id][dest.node_id] = { :p =>1, :alpha =>1, :theta => 2 }
          end
        end
      end

    end

    if debug?
      puts
      puts "Node parameters after filling gaps with any defaults."
      p @node_parameters
    end

  end

  # Populate the @nodes object with n new nodes, indexed incrementally from 0.
  # If n is omitted, the value of 'numnodes' in the scenario configuration is
  # used instead.
  #
  def createNodes n=@CONFIG[:numnodes]
    n.times { |i|
      @nodes.add Node.new i, debug?
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

      # Step 1 tells the node what its current set of possible nodes are, and
      # asks the node for its chosen relevant neighbourhood. It is
      # responsible for determining this based on its prior knowledge (e.g. tau
      # values).
      #
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

  def debug?
    @debug
  end

end
