require "set" # For storing collections of nodes.
require "yaml" # For parsing the configuration files.
require "deep_merge" # For merging simulator and experiment configurations.
require "fileutils" # For recursively creating directories.

require "neighbourhood-selection/util"
require "neighbourhood-selection/node"
require "neighbourhood-selection/gamma"

class Simulator

  attr_reader :nodes

  # Create a new Simulator object and associated requirements.
  #
  def initialize scenario_name, variant_name, sim_id, scenario_config_file, taus_file, node_utilities_file, conjoint_utilities_file, random_seed, experiment_config=Hash.new

    # Load simulation scenario specific configuration
    @SCENARIO_CONFIG = YAML.load_file(scenario_config_file)[scenario_name]

    unless @SCENARIO_CONFIG
      raise "No configuration found for scenario #{scenario_name}."
    end

    # YAML files are parsed with keys as Strings rather than symbols, which we
    # use internally. So, convert the Strings to symbols.
    @SCENARIO_CONFIG = Hash.transform_keys_to_symbols(@SCENARIO_CONFIG)

    # We also need to process some string values into symbols.
    @SCENARIO_CONFIG[:node_strategies] = Hash.transform_values_to_symbols(@SCENARIO_CONFIG[:node_strategies])

    # Make a deep local copy of the experiment config
    @config = Marshal.load(Marshal.dump(experiment_config))

    # Merge simulation configuration and experiment configuration.
    # Experiment configuration takes precedence, and will overwrite scenario
    # "defaults", if specified. We assume that the config has already been
    # "cleaned" to use symbols.
    @config.deep_merge(@SCENARIO_CONFIG)

    # TODO: It would probably make much more sense to do this above bit in
    # reverse, i.e. by rewriting a custom deep_merge method which merges the
    # experiment config into the locally created scenario config. Then we
    # wouldn't need to rely on that gem either.

    # Should we print debugging output?
    @debug = @config[:debug]

    # Set this simulation's name and ID. This tells us we have initialized it.
    @scenario_name = scenario_name
    @variant_name = variant_name
    @sim_id = sim_id

    # Initialise timestep to be zero
    @timestep = 0

    # Where to send the output data
    @taus_file = taus_file
    @node_utilities_file = node_utilities_file
    @conjoint_utilities_file = conjoint_utilities_file

    # Store the nodes in a set rather than an array or anything else.
    @nodes = Set.new

    # Create the nodes themselves.
    createNodes

    # Create the environment for the nodes, e.g. the network structure.
    createEnvironment

    # Create events (dynamics, etc.)
    createEvents

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

    if @config[:node_parameters]
      @node_parameters = @config[:node_parameters]
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

      # Is this node initially connected to the network?
      if @node_parameters[source.node_id][:connected] == false
        source.disconnect
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
  def createNodes n=@config[:numnodes], strategies=@config[:node_strategies]
    n.times { |i|

      # Determine node communication strategy
      if strategies and strategies[i]
        strategy = strategies[i]
      else
        strategy = :broadcast
      end

      # We initially start with every node connected. They will be disconnected
      # in createEnvironment if they are specified to start disconnected in the
      # configuration file.
      connected = true

      # Add the node
      @nodes.add Node.new i, strategy, connected, @config[:node_debug]
    }

    if debug?
      puts
      puts "Node parameters after filling gaps with any defaults."
      @nodes.each { |n| p n }
      puts
    end


  end


  # Populate the @nodes object with n new nodes, indexed incrementally from 0.
  # If n is omitted, the value of 'numnodes' in the scenario configuration is
  # used instead.
  #
  def createEvents events=@config[:events]
    @events = {}

    # If there are no events, don't do anything
    unless events
      return
    end

    # Create each event indexed by its time
    events.each do |name, event|

      unless @events[event[:time]]
        @events[event[:time]] = Set.new
      end

      @events[event[:time]].add ({:name => name}.merge(event))

    end

    if debug?
      puts "Created the following events:"
      @events.each do |time, eventset|
        puts "#{time}:"
        eventset.each do |event|
          puts "  #{event[:name]}"
        end
      end
    end

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
  #
  # First, this triggers any events for this time step, then it iterates through
  # each node, running their update_neighbourhood (step1) and
  # update_benefits_and_costs (step2) methods.
  #
  # Typically, this means they set their relevant neighbourhood based on
  # previous knowledge (e.g. tau values), communicate and sample benefits and
  # costs. They then update their tau values accordingly.
  #
  def step

    # First, we increment the timestep.
    # Putting this first means that the first time step will be 1, not 0.
    @timestep += 1

    # Secondly we trigger any events which have been defined for this time step.
    if @events[@timestep]
      @events[@timestep].each do |event|
        if debug?
          puts "Timestep is #{@timestep}, triggering event #{event[:name]}"
        end

        # Do whatever is required
        handle_event event

      end
    end


    # Thirdly, we iterate through each node, running one simulation cycle for
    # each.
    @nodes.each do |node|

      # Step 1 tells the node what its current set of possible nodes are, and
      # asks the node for its chosen relevant neighbourhood. It is
      # responsible for determining this based on its prior knowledge (e.g. tau
      # values).
      #
      selected_neighbourhood = node.update_neighbourhood possible_nodes_for node

      # Next we determine the benefit and cost associated with each edge in the
      # relevant neighbourhood of the node.
      benefits_and_costs = { }
      selected_neighbourhood.each do |neighbour|
        benefits_and_costs[neighbour.node_id] =
          get_benefits_and_costs node.node_id, neighbour.node_id
      end

      # In step 2, we tell the node what the benefits and costs were, so that it
      # can update its knowledge of each node (e.g. tau values).
      node.update_benefits_and_costs benefits_and_costs

    end

    # Finally, we yield to a block which may have been passed in to the step
    # method. This can be used for printing out or otherwise collecting
    # information about the state of the simulation at the end of the time
    # step.
    yield

  end


  # This returns the set of all nodes it would be possible for the given node to
  # communicate with, given the current set of nodes and network connectivity.
  def possible_nodes_for node
    if node.is_connected?
      @nodes.find_all { |n| n.node_id != node.node_id and n.is_connected? }
    else
      Set.new
    end
  end


  # Handle an event that has been triggered.
  def handle_event event

    case event[:action]
    when "remove"
      remove_node event[:node]
    when "add"
      add_node event[:node]
    else
      raise "Unable to handle event named #{event[:name]} with action #{event[:action]}."
    end

  end


  # Remove the node with id 'node_id' from the network.
  def remove_node node_id

    if debug?
      puts "--> Removing node #{node_id}."

      unless @nodes.find { |n| n.node_id==node_id}.is_connected?
        puts "--> Warning: attempting to remove a node which is not connected!"
      end
    end

    # We don't actually delete the node object, just remove it from the network.
    @nodes.find { |n| n.node_id==node_id }.disconnect

  end

  # Connect the node with id 'node_id' to the network. Note that the node must
  # have been created when the simulation was initialized.
  def add_node node_id
    if debug?
      puts "--> Adding node #{node_id}."

      if @nodes.find { |n| n.node_id==node_id}.is_connected?
        puts "--> Warning: attempting to connect a node which is already connected!"
      end
    end

    # We can assume the node did previously exist here, we are just connecting,
    # not creating.
    @nodes.find { |n| n.node_id==node_id }.connect

  end


  def debug?
    @debug
  end


  def run

    unless @scenario_name
      raise "Tried to run a simulation which has not yet been initialized."
    end

    unless @timestep == 0
      raise "Tried to run a simulation which has already been run."
    end

    # Some initial debugging output
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
        # This block is executed at the end of each time step. It can be used
        # for collecting data and printing it out, for example.

        # We're only really interested in tracking one node, node 0
        interesting_node = @nodes.find { |n| n.node_id==0 }

        # This output generates long data files, for use with R.

        # TODO: This bit is so hacky it's sad. Suggestions welcome.
        #
        # First create column headers for the output files, if this is the first
        # time we write to the file.
        if @taus_file.size == 0
          @taus_file.puts "Variant Trial Timestep #{list_nodes_except 0}"
        end

        if @node_utilities_file.size == 0
          @node_utilities_file.puts "Variant Trial Timestep #{list_nodes_except 0}"
        end

        if @conjoint_utilities_file.size == 0
          @conjoint_utilities_file.puts "Variant Trial Timestep Utility"
        end

        # Output the tau values associated with each possible node.
        @taus_file.print "#{@variant_name} #{@sim_id} #{@timestep} "
        interesting_node.print_taus @taus_file
        @taus_file.puts

        # Output the utility values obtained from each possible node.
        @node_utilities_file.print "#{@variant_name} #{@sim_id} #{@timestep} "
        interesting_node.print_total_utilities @node_utilities_file
        @node_utilities_file.puts

        # Output the cumulative conjoint utility so far
        @conjoint_utilities_file.print "#{@variant_name} #{@sim_id} #{@timestep} "
        interesting_node.print_cumulative_conjoint_utility @conjoint_utilities_file
        @conjoint_utilities_file.puts

      end
    end

  end

  # Returns a string containing a space separated list of all node IDs known
  # except for n, sorted in ascending order by ID.
  def list_nodes_except id
    @nodes
      .reject { |n| n.node_id == id }  # Don't print the interesting itself,
      .sort_by { |n| n.node_id }      # Make sure they're in ID order,
      .collect {|n| n.node_id}        # Only print the IDs, not the objects,
      .join " "
  end

end
