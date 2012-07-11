require "neighbourhood-selection/experiment"

class Experiment_Set

  # Allow callers to query the experiments we're set up to run.
  attr_reader :experiment_list
  attr_reader :config_file


  def initialize experiments, config_file="./config/experiment.yml"

    # A list of the names of the experiments to run
    @experiment_list = experiments
    @config_file = config_file

    # Check config file exists.
    unless File.exists? config_file
      raise "Error: Can't find the experiment configuration file."
    end

  end


  def run run_experiments=true, generate_graphs=true, generate_graph_titles=true, generate_stats=true

    # Run each experiment in turn.
    @experiment_list.each do |experiment_name|
      filenames = create_and_run_experiment experiment_name, run_experiments, generate_graphs, generate_graph_titles, generate_stats
      puts "Experiment #{experiment_name} completed." if run_experiments
      puts "The following data sets are available for experiment #{experiment_name}:"
      filenames.each { |name, file| puts "--> #{name}: #{file}" }
    end

  end


  private

  # Actually create an experiment object, and run it.
  def create_and_run_experiment experiment_name, run_experiments=true, generate_graphs=true, generate_graph_titles=true, generate_stats=true

      # If we've been passed a --config <filename>, then use that instead of
      # 'config/experiment.yml'
      #
      # Create the simulation itself:
      experiment = Experiment.new experiment_name, @config_file

      # Run the experiment using the config given.
      # This returns a hash of the names of files that data was written to.
      experiment.run run_experiments, generate_graphs, generate_graph_titles, generate_stats

  end


  #def calculate_average_stats

  #end

end

