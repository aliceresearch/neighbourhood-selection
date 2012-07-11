require "rinruby"

# TODO: DRY w.r.t experiment_analyser. Create common module or superclass?

class Experiment_Set_Analyser

  def initialize datafiles, column_types
    @datafiles = datafiles

    # Check we're not trying to analyse nothing
    @datafiles.each do |datafile|
      unless File.exists? datafile
        R.quit
        raise "Data file #{datafile} does not exist."
      end
    end

    # Create an R instance for us to use
    # We don't use the default one, since we want to set echo to off.
    #
    # TODO: Can I do this with R.echo(enable=false) ?

    @r = RinRuby.new(:echo=>false)

    # Convert the array of column types to an R friendly list string.
    # TODO: Definitely a DRY candidate at the least!
    column_types = column_types.to_s.gsub( /[\[\]]/, '').gsub( /"/, '\'')

    # Load the data into the R session
    @datafiles.each_with_index do |datafile, i|
      print "Loading data file #{datafile} as data.#{i}..."
      @r.eval "data.#{i} <- read.table( '#{datafile}', header = TRUE,
                                    colClasses = c(#{column_types}))"
      puts " done."
    end
  end


  # Calculate some statistics over the whole set of experiments.
  def create_set_stats

    puts "Going to calculate some overall statistics for the experiment set."
    puts "Got the following data files:"
    p @datafiles

    puts "NOT IMPLEMENTED YET."

  end

end
