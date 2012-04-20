require "rinruby"

class Experiment_Graph

  def initialize datafile, pdffile, title, column_types, y_max=nil

    print "Generating graph for dataset #{datafile}... "

    # Create an r instance for us to use
    @r= RinRuby.new(:echo=>false)

    # Convert the array of column types to an R friendly list string.
    column_types = column_types.to_s.gsub( /[\[\]]/, '').gsub( /"/, '\'')

    # Use ggplot2 for plotting.
    @r.eval "library(ggplot2)"

    @r.eval "data <- read.table( '#{datafile}', header = TRUE,
                      colClasses = c(#{column_types}))"

    # We want to render straight to PDF, not to the screen.
    @r.eval "pdf('#{pdffile}')"

    # The plot command string.
    @plotstring = "qplot(Timestep, Utility, data = data,
                    colour=Trial, geom = c('point', 'line'),
                    main = '#{title}') +
                    opts( legend.position = 'none' )"
    if y_max
      @plotstring += "+ ylim(0, #{y_max})"
    end

    @r.eval @plotstring

    # Close the PDF file.
    @r.eval "dev.off()"

    puts "done!"

  end
end
