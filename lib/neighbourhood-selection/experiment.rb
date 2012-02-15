require "yaml"
require "neighbourhood-selection/simulator"

class Experiment

  # Create a new Experiment object.
  #
  def initialize experiment_name, config_file="./config/experiment.yml"

    # Load experimental setup configuration
    @CONFIG = YAML.load_file(config_file)[experiment_name]

    unless @CONFIG
      raise "No configuration found for experiment #{experiment_name}."
    end

    # YAML files are parsed with keys as Strings rather than symbols, which we
    # use internally. So, convert the Strings to symbols.
    @CONFIG = Hash.transform_keys_to_symbols(@CONFIG)

    # We also need to process some string values into symbols.
    # Well, if we did, this is how we'd do it:
    #@CONFIG[:node_strategies] = Hash.transform_values_to_symbols(@CONFIG[:node_strategies])

    # Should we print debugging output?
    @debug = @CONFIG[:debug] or false

    # Set this simulation's name. This tells us we have initialized it.
    @experiment_name = experiment_name

    # How many runs of the experiment should we conduct?
    @num_experiments = @CONFIG[:num_experiments]

    # What filename prefix should be used?
    if @CONFIG[:filename_prefix]
      @filename_prefix = @CONFIG[:filename_prefix]
    else
      @filename_prefix = ""
    end

    # What file should the simulator use for its config?
    @sim_config_file = "./config/simulation.yml"

    # And what simulation should be loaded from that file?
    @sim_name = @CONFIG[:sim_name]

    # Read in the seeds for the random number generator.
    @seeds = []
    File.open('./config/seeds').each do |line|
      @seeds << line.to_i
    end

    # Some validation
    if @sim_name == "" or !@sim_name
      raise "No simulation name given in experiment configuration file."
    end

    if @seeds.length < @num_experiments
      raise "Not enough random seeds for #{@num_experiments} experiments."
    end

  end


  def run
    # For now, experiments are conducted in series.
    # TODO: It would be nice if there was something more clever here that could
    # parallelise them.
    #
    # Loop through them here:
    for exp in 0..@num_experiments
      if debug?
        puts "Experiment #{exp} starting."
      end

      # Create simulator object
      sim = Simulator.new @sim_name, exp, @sim_config_file, @filename_prefix, @seeds[exp]

      sim.run

      if debug?
        puts "Experiment #{exp} finished."
      end
    end

  end


  def debug?
    @debug
  end

end
