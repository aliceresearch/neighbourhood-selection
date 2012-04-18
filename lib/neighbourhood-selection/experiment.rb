require "yaml" # For parsing the configuration.
require "fileutils" # For recursively creating directories.

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
    # The only place this will be needed is if the experiment contains variants,
    # which specify node strategies:
    if @CONFIG[:scenario_variants]
      @CONFIG[:scenario_variants].each do |name,config|
        config[:node_strategies] = Hash.transform_values_to_symbols(config[:node_strategies])
      end
    end

    # Should we print debugging output?
    @debug = (@CONFIG[:debug] or false)

    # Set this simulation's name. This tells us we have initialized it.
    @experiment_name = experiment_name

    # How many runs of the experiment / each variant should we conduct?
    @num_trials = (@CONFIG[:num_trials] or 1)

    # Where should we put the results?
    @results_dir = (@CONFIG[:results_dir] or "results")

    # Create the results directory, if needed.
    create_results_dir

    # What filename prefix should be used?
    @filename_prefix = (@CONFIG[:filename_prefix] or experiment_name)

    # What file should the simulator use for its config?
    @scenario_config_file = (@CONFIG[:scenario_config_file] or "./config/scenarios.yml")

    # And what simulation should be loaded from that file?
    @scenario_name = @CONFIG[:scenario]

    # Read in the seeds for the random number generator.
    begin
      @seeds = []
      File.open('./config/seeds').each do |line|
        @seeds << line.to_i
      end
    rescue
      raise "Error: No random seed file found in ./config/seeds."
    end

    # Some validation
    if @scenario_name == "" or !@scenario_name
      raise "No simulation name given in experiment configuration file."
    end

    if @seeds.length < @num_trials
      raise "Not enough random seeds for #{@num_trials} trials."
    end

  end


  # Run a particular experimental variant.
  # If no variant config is given, the vanilla scenario will be run.
  def run_variant variant_filename_prefix="", variant_config=Hash.new

    # Where to put and what to to call this variant's results files:
    variant_filename_prefix = @results_dir + "/" + @filename_prefix + "-" + variant_filename_prefix

    # Open files
    taus_file = File.open("#{variant_filename_prefix}.taus", 'w')
    node_utilities_file = File.open("#{variant_filename_prefix}.node_utilities", 'w')
    conjoint_utilities_file = File.open("#{variant_filename_prefix}.conjoint_utilities", 'w')

    # For now, experiments are conducted in series.
    # TODO: It would be nice if there was something more clever here that could
    # parallelise them.
    #
    # Loop through them here:
    for trial in 0..@num_trials-1
      if debug?
        puts "Trial #{trial} starting."
      end

      # Create simulator object
      sim = Simulator.new @scenario_name, trial, @scenario_config_file, taus_file, node_utilities_file, conjoint_utilities_file, @seeds[trial], variant_config

      sim.run

      if debug?
        puts "--> Trial #{trial} finished."
      end
    end

    # Close files
    taus_file.close
    node_utilities_file.close
    conjoint_utilities_file.close

  end


  # Run this experiment, or set of experimental variants
  def run
    if @CONFIG[:scenario_variants]
      @CONFIG[:scenario_variants].each do |variant_name, variant_config|

        # Was the filename overridden in the variant config?
        if variant_config[:filename_prefix]
          variant_filename_prefix = variant_config[:filename_prefix]
        else
          variant_filename_prefix = variant_name.to_s
        end

        # Run the experiment itself
        run_variant variant_filename_prefix, variant_config

        if debug?
          puts "Experimental variant #{variant_filename_prefix} finished."
        end

      end
    else
        # No variants specified, just run the vanilla scenario
        run_variant

        if debug?
          puts "Experiment finished."
        end

    end

  end


  # Create the directory currently in results_dir, if it does not yet exist.
  # Some useful warnings are also included.
  def create_results_dir
    if File.directory?(@results_dir)
      warn "Warning: Results directory already exists. I may be overwriting previous results."
    else
      begin
        FileUtils.mkpath(@results_dir)
      rescue
        warn "Error: The results directory #{@results_dir} does not exist and I can't create it."
        warn "Check your configuration."
        exit
      end
      if debug?
        puts "Created results directory: #{@results_dir}."
      end
    end
  end


  def debug?
    @debug
  end

end
