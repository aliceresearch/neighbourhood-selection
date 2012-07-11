require "rinruby"

class Experiment_Set_Analyser

  def initialize datafiles, column_types
    @datafiles = datafiles



  end


  # Calculate some statistics over the whole set of experiments.
  def create_set_stats

    puts "Going to calculate some overall statistics for the experiment set."
    puts "Got the following data files:"
    p @datafiles

    puts "NOT IMPLEMENTED YET."

  end

end
