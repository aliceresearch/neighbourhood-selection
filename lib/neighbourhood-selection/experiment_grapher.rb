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

    # Here you can set theming options to be applied to all plots.
    # This must be done manually though in the relevant plotting method below.
    # This can be very simple, empty or as complex as you like.
    # Here's an example which makes lots of things transparent:
    #
    #@default_theme = "opts(panel.background = theme_rect(fill = 'transparent', colour = NA),
                      #panel.grid.minor = theme_blank(), 
                      #panel.grid.major = theme_blank(),
                      #plot.background = theme_rect(fill = 'transparent',colour = NA))"
    #
    # And here's a really simple example that just uses a predefined theme in
    # its entirety:
    #
    # @default_theme = "theme_blank()"
    #
    # For more information about themes, check out http://sape.inf.usi.ch/quick-reference/ggplot2/themes
    #
    @default_theme = "theme_bw()"

  end


  # Create a graph from the loaded dataset showing values for every run as an
  # individual series.
  def create_runs_graph pdffile, title, y_min=nil, y_max=nil

    print "Generating individual runs graph for dataset #{@dataset_name}... "

    # We want to render straight to PDF, not to the screen.
    @r.eval "pdf('#{pdffile}')"

    # The plot command string.
    plotstring = "qplot(Timestep, Utility, data = data,
                   colour=Variant, geom = c('point', 'line')) +
                   #{@default_theme} +
                   opts(title = '#{title}') +
                   opts(legend.position = 'none')"
    if y_min and y_max
      plotstring += "+ coord_cartesian(ylim = c(#{y_min}, #{y_max}))"
      plotstring += "+ scale_y_continuous(breaks=seq(#{y_min},#{y_max},#{((y_max-y_min)/10).round(-3)}))"
    end

    @r.eval plotstring

    # Close the PDF file.
    @r.eval "dev.off()"

    puts "done!"

  end

  # Create a graph from the loaded dataset showing mean and standard deviation
  # between runs.
  def create_summary_graph pdffile, title, y_min=nil, y_max=nil

    print "Generating summary graph for dataset #{@dataset_name}... "

    # We want to render straight to PDF, not to the screen.
    @r.eval "pdf('#{pdffile}')"

    # The plot command string.
    plotstring = "ggplot(data, aes(x=Timestep, y=Utility, colour=Variant)) +
                  #{@default_theme} +
                  opts(title = '#{title}') +
                  stat_summary(fun.ymin = function(x) mean(x)-sd(x), fun.ymax = function(x) mean(x)+sd(x), alpha = 0.6, geom = c('ribbon')) +
                  stat_summary(fun.y = mean, size = 1.0, geom = c('line'))"

    if y_min and y_max
      plotstring += "+ coord_cartesian(ylim = c(#{y_min}, #{y_max}))"
      plotstring += "+ scale_y_continuous(breaks=seq(#{y_min},#{y_max},#{((y_max-y_min)/10).round(-3)}))"
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
