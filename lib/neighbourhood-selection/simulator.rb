require "set"
require "yaml"
require "neighbourhood-selection/util"
require "neighbourhood-selection/node"
require "neighbourhood-selection/gamma"

class Simulator

  attr_reader :nodes

  @debug = false

  # Create a new Simulator object and associated requirements.
  #
  def initialize sim_name, sim_id, config_file, output_file_prefix, random_seed

    # Load simulation scenario specific configuration
    @CONFIG = YAML.load_file(config_file)[sim_name]

    unless @CONFIG
      raise "No configuration found for simulation #{sim_name}."
    end

    # YAML files are parsed with keys as Strings rather than symbols, which we
    # use internally. So, convert the Strings to symbols.
    @CONFIG = Hash.transform_keys_to_symbols(@CONFIG)

    # We also need to process some string values into symbols.
    @CONFIG[:node_strategies] = Hash.transform_values_to_symbols(@CONFIG[:node_strategies])

    # Should we print debugging output?
    @debug = @CONFIG[:debug]

    # Set this simulation's name and ID. This tells us we have initialized it.
    @sim_name = sim_name
    @sim_id = sim_id

    # What filename stub should be used?
    if @CONFIG[:filename_suffix]
      @filename = output_file_prefix + "-" + @CONFIG[:filename_suffix]
    else
      @filename = output_file_prefix
    end

    # Store the nodes in a set rather than an array or anything else.
    @nodes = Set.new

    # Create the nodes themselves.
    createNodes

    # Create the environment for the nodes, e.g. the network structure.
    createEnvironment

    @random = Random.new random_seed
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
      puts "Network parameters read from configuration file:"
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
      puts "Network parameters after filling gaps with any defaults."
      p @node_parameters
      puts
    end

  end

  # Populate the @nodes object with n new nodes, indexed incrementally from 0.
  # If n is omitted, the value of 'numnodes' in the scenario configuration is
  # used instead.
  #
  def createNodes n=@CONFIG[:numnodes], strategies=@CONFIG[:node_strategies]
    n.times { |i|

      # Determine node communication strategy
      if strategies and strategies[i]
        strategy = strategies[i]
      else
        strategy = :broadcast
      end

      # Add the node
      @nodes.add Node.new i, strategy, @CONFIG[:node_debug]
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


  def run

    unless @sim_name
      raise "Tried to run a simulation which has not yet been initialized."
    end

    # Use an additional filename suffix if we have been passed a sim_id
    if @sim_id
      sim_id_suffix = "." + @sim_id.to_s
    else
      sim_id_suffix = ""
    end

    # Set up output files
    taus_file = File.open("#{@filename}.taus" + sim_id_suffix, 'w')
    node_utilities_file = File.open("#{@filename}.node_utilities" + sim_id_suffix, 'w')
    conjoint_utilities_file = File.open("#{@filename}.conjoint_utilities" + sim_id_suffix, 'w') 

    # Some initial output
    if debug?
      puts "Beginning simulation with #{@nodes.length} nodes."
      print "Node IDs are:"
      @nodes.each { |i|
        print " #{i.node_id}"
      }
      puts "."
    end

    # Run a number of simulation steps.
    # Simulator.step can take a block. If one is passed in, then this is
    # executed at the end of each time step.
    #
    10000.times do
      step do
        # This block is executed at the end of each time step. It can be used for
        # collecting data and printing it out, for example.

        # We're only really interested in tracking one node, node 0
        interesting_node = @nodes.find { |n| n.node_id==0 }

        # Print out the utility and tau associated with each possible node.
        interesting_node.print_taus taus_file
        interesting_node.print_total_utilities node_utilities_file

        # Just print the cumulative conjoint utility so far
        interesting_node.print_cumulative_conjoint_utility conjoint_utilities_file
      end
    end

    # Close the files
    taus_file.close
    node_utilities_file.close
    conjoint_utilities_file.close
  end

end
