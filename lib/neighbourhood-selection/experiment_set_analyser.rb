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
  def create_set_stats outfilename

    puts "Going to calculate some overall statistics for the experiment set."
    puts "Got the following data files:"
    p @datafiles

    # Pre-process each datafile, to get what we need:
    @datafiles.each_with_index do |datafile, i|
      # Create data frames with just the final values in it
      # (i.e. throw out all timesteps but the last one:
      @r.eval "subset(data.#{i}, subset=(Timestep>=max(Timestep))) -> data.#{i}.final.unnormalised"

      # Normalise each data set by its best known value, to make them comparable
      # across scenarios with different maxima.
      @r.eval "max(data.#{i}.final.unnormalised$Utility) -> maximum"
      @r.eval "min(data.#{i}.final.unnormalised$Utility) -> minimum"
      @r.eval "with(data.#{i}.final.unnormalised, data.frame(Variant=Variant, Trial=Trial, Utility=(Utility-minimum)/(maximum-minimum))) -> data.#{i}.final"
    end

    # Concatenate data sets from all experiments (scenarios) into data.final
    puts "going to try:"
    r_string = "data.final <- rbind("
    (0..@datafiles.size-1).each do |i|
      r_string += "data.#{i}.final"
      if i < @datafiles.size-1
        r_string += ", "
      end
    end
    r_string += ")"

    puts r_string

    @r.eval r_string


    # TODO: This is totally copied from experiment_analyser. DRY DRY DRY.

    # Using this new slimmed down data frame, calculate the mean and standard
    # deviations for each variant, across all tested scenarios.
    @r.eval "tapply(data.final$Utility, data.final$Variant, mean) -> means"
    @r.eval "tapply(data.final$Utility, data.final$Variant, sd) -> sds"

    # Format for returning to ruby
    @r.eval "names(means) -> variants"
    @r.eval "matrix(means) -> means"
    @r.eval "matrix(sds) -> sds"

    # Now, find the variant with the highest mean.
    best_variant = @r.variants.each_with_index.max_by { |name, i| @r.means[i,0] }[0]

    # Next, calculate pairwise Wilcoxon Rank Sum test between the variant with
    # the best mean and each other variant.
    #
    # Use data.final, which we created above, to compare samples of the final
    # timestep's utility values.
    p_values = {}
    @r.variants.each_with_index do |comparator_variant, i|

      unless comparator_variant == best_variant
        @r.eval "a <- subset(data.final, subset=(Variant==\"#{best_variant}\"))"
        @r.eval "b <- subset(data.final, subset=(Variant==\"#{comparator_variant}\"))"

        @r.eval "result <- wilcox.test(a$Utility, b$Utility, correction=TRUE)"
        @r.eval "p <- result$p.value"

        p_values[comparator_variant] = @r.p
      end

    end


    # Finally, let's create some pretty output
    File.open(outfilename, "w") do |outfile|
      outfile.puts "Variant with best mean: #{best_variant}"
      outfile.puts
      outfile.puts "The following datasets were averaged:"
      @datafiles.each { |file| outfile.puts "--> #{file}" }
      outfile.puts
      outfile.puts "Final utility values, by variant:"
      outfile.puts "-------------------------------------------------------------------"
      outfile.puts "Variant".center(25," ") + "\t\t  Mean   \t   SD"
      outfile.puts "-------------------------------------------------------------------"
      @r.variants.each_with_index do |name, i|
        outfile.puts name.center(25," ") + "\t\t" + "%0.3f" % @r.means[i,0] + "\t" + "%0.3f" % @r.sds[i,0]
      end
      outfile.puts "-------------------------------------------------------------------"
      outfile.puts
      outfile.puts "Wilcoxon Rank Sum test results. Comparing #{best_variant} pairwise with:"
      outfile.puts "-------------------------------------------------------------------"
      outfile.puts "Variant".center(25," ") + "\t\t p value\tSig Diff?"
      outfile.puts "-------------------------------------------------------------------"
      @r.variants.each_with_index do |name, i|
        unless name == best_variant
          outfile.print name.center(25," ") + "\t\t " + "%0.5f" % p_values[name]
          if p_values[name] <= 0.05
            outfile.puts "\t   *"
          else
            outfile.puts
          end
        end
      end
      outfile.puts "-------------------------------------------------------------------"
    end

  end

end
