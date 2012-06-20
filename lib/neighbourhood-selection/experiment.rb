require "yaml" # For parsing the configuration.
require "fileutils" # For recursively creating directories.

require "neighbourhood-selection/experiment_grapher"
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

    # Should we actually run experiments, or assume they've been run already and
    # the data is present?
    @run_experiments = (@CONFIG[:run_experiments] or true)

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
  def run_variant variant_name="", variant_config=Hash.new, run_experiments, generate_graphs, generate_graph_titles

    # Was the filename overridden in the variant config?
    if variant_config[:filename_prefix]
      variant_filename_prefix = variant_config[:filename_prefix]
    else
      variant_filename_prefix = variant_name.to_s
    end

    # Where to put and what to to call this variant's results files:
    variant_filename_prefix = @results_dir + "/" + @filename_prefix + "-" + variant_filename_prefix

    # Actual filenames to use
    taus_filename = "#{variant_filename_prefix}.taus"
    node_utilities_filename = "#{variant_filename_prefix}.node_utilities"
    conjoint_utilities_filename = "#{variant_filename_prefix}.conjoint_utilities"

    # We might not need to actually run the experiments, if for example, we've
    # just been asked to recreate the graphs.
    if run_experiments

      # Open files
      taus_file = File.open(taus_filename, 'w')
      node_utilities_file = File.open(node_utilities_filename, 'w')
      conjoint_utilities_file = File.open(conjoint_utilities_filename, 'w')

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

        # If this is the first trial, we should first create column headers for
        # the output files.
        #
        # This is done here since we have to know how many nodes were specified in
        # the scenario, hence a simulator must have been created using that
        # configuration.
        # TODO: I don't like this being here, it feels hacky. Suggestions welcome.
        if trial == 0
          taus_file.puts "Trial Timestep #{sim.list_nodes_except 0}"
          node_utilities_file.puts "Trial Timestep #{sim.list_nodes_except 0}"
          conjoint_utilities_file.puts "Trial Timestep Utility"
        end

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


    # Generate variant-specific graph, if requested.
    # The column types are:
    #   - factor: trial number
    #   - integer: timestep
    #   - numeric: conjoint utility value
    if generate_graphs

      if generate_graph_titles
        graph_title = "Conjoint Utility: #{@scenario_name}"
        if variant_name
          graph_title = graph_title + "-" + variant_name.to_s
        end
      else
        graph_title = ""
      end

      begin
        # Create a grapher object for this dataset
        grapher = Experiment_Grapher.new(conjoint_utilities_filename,
                                         ["factor", "integer", "numeric"])

        # Produce a graph showing each individual run
        grapher.create_runs_graph("#{conjoint_utilities_filename}-individual-runs.pdf",
                                  graph_title,
                                  variant_config[:max_conjoint_utility])

        # Produce a graph showing the mean and standard deviation between runs
        grapher.create_summary_graph("#{conjoint_utilities_filename}-summary.pdf",
                                     graph_title,
                                     variant_config[:max_conjoint_utility])

      rescue Exception => e
        # Things can go wrong when using R and reading from files
        puts e.message
      end

    end

  end


  # Run this experiment, or set of experimental variants
  def run run_experiments=true, generate_graphs=true, generate_graph_titles=true

    # TODO: DRY!

    if @CONFIG[:scenario_variants]
      @CONFIG[:scenario_variants].each do |variant_name, variant_config|

        # Run the experiment itself
        run_variant variant_name, variant_config, run_experiments, generate_graphs, generate_graph_titles

        if debug?
          puts "Experimental variant #{variant_filename_prefix} finished."
        end

      end
    else
      # No variants specified, just run the vanilla scenario
      run_variant "", Hash.new, run_experiments, generate_graphs, generate_graph_titles

      if debug?
        puts "Experiment finished."
      end

    end

    # Generate cross-variant comparison graphs, if requested.
    if generate_graphs
      # TODO: Generate graphs here to compare variants.
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
