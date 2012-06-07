require "rinruby"

# TODO: This whole thing could do with some better error handling.

class Experiment_Grapher

  def initialize datafile, column_types

    # So we can see this in other methods
    @dataset_name = datafile

    # Check we're not trying to plot nothing
    unless File.exists? datafile
      R.quit
      raise "Data file does not exist."
    end

    # Create an R instance for us to use
    # We don't use the default one, since we want to set echo to off.

    @r = RinRuby.new(:echo=>false)

    # Convert the array of column types to an R friendly list string.
    column_types = column_types.to_s.gsub( /[\[\]]/, '').gsub( /"/, '\'')

    # Load ggplot2 for plotting.
    @r.eval "library(ggplot2)"

    # Load the data into the R session
    @r.eval "data <- read.table( '#{datafile}', header = TRUE,
                                  colClasses = c(#{column_types}))"

  end


  # Create a graph from the loaded dataset showing values for every run as an
  # individual series.
  def create_runs_graph pdffile, title, y_max=nil

    print "Generating individual runs graph for dataset #{@dataset_name}... "

    # We want to render straight to PDF, not to the screen.
    @r.eval "pdf('#{pdffile}')"

    # The plot command string.
    plotstring = "qplot(Timestep, Utility, data = data,
                   colour=Trial, geom = c('point', 'line'),
                   main = '#{title}') +
                   opts( legend.position = 'none' )"
    if y_max
      plotstring += "+ ylim(0, #{y_max})"
    end

    @r.eval plotstring

    # Close the PDF file.
    @r.eval "dev.off()"

    puts "done!"

  end

  # Create a graph from the loaded dataset showing mean and standard deviation
  # between runs.
  def create_summary_graph pdffile, title, y_max=nil

    print "Generating summary graph for dataset #{@dataset_name}... "

    # We want to render straight to PDF, not to the screen.
    @r.eval "pdf('#{pdffile}')"

    # The plot command string.

    plotstring = "ggplot(data, aes(x=Timestep, y=Utility, main = '#{title}')) +
                  #{@default_theme} +
                  stat_summary(fun.y = 'mean', fun.ymin = min, fun.ymax = max, colour = 'grey', alpha = 0.7, geom = c('errorbar')) +
                  stat_summary(fun.y = 'mean', fun.ymin = min, fun.ymax = max, color = 'black', size = 1.0, geom = c('point', 'line'))"
                  #opts(legend.position = 'none')

    if y_max
      plotstring += "+ ylim(0, #{y_max})"
    end

    @r.eval plotstring

    # Close the PDF file.
    @r.eval "dev.off()"

    puts "done!"

  end


  def close_r_sessions
    # Quit our R session and the annoyingly created default one.
    @r.quit
    R.quit
  end

end
