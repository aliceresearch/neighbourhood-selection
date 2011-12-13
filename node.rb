require "set"

class Node

  attr_reader :node_id

  def initialize id
    @taus = {}
    @node_id = id
    @evaporation_rate = 0.01
    @delta = 1
    @weights = { :beta => 0.5, :gamma => 0.5 }
    @random = Random.new @node_id

    # Choose one of these three:
    #@communication_strategy = :broadcast
    #@communication_strategy = :smooth
    @communication_strategy = :step

    # Communication strategy parameters:
    @step_epsilon = 0.95
    @step_eta = 0.01

  end


  def step1 possible_nodes
    @taus.keep_if { |i, t|
      possible_nodes.find { |n| n.node_id == i }
    }

    possible_nodes.each { |b|
      if !@taus[b.node_id]
        @taus[b.node_id] = 1.0
      end
    }

    relevant_neighbourhood = select_relevant_neighbourhood_from possible_nodes
  end

  def step2 benefits_and_costs, possible_nodes
    possible_nodes.each { |n|
      @taus[n.node_id]= (1-@evaporation_rate) * @taus[n.node_id]
    }


    benefits_and_costs.each { |i, values|
      if (utility values) > 0
        @taus[i] = @taus[i] + @delta
      end
    }
  end

  def utility values
    @weights[:beta] * values[:beta] - @weights[:gamma] * values[:gamma]
  end

  # Print the node ID and the current values in @taus.
  # Formatting is suitable for Gnuplot, Octave or similar.
  # E.g.
  # 0 0.97 0.86 0.51 0.01 0.05
  #
  def print_taus
    print @node_id
    @taus.each { |i,t|
      # puts "node_id #{i} tau #{t}"
      print " #{t}"
    }
    puts
  end

  def select_relevant_neighbourhood_from possible_nodes
    case @communication_strategy
      when :broadcast then select_all_from possible_nodes
      when :smooth then select_smooth_from possible_nodes
      when :step then select_step_from possible_nodes
    end
  end

  def select_smooth_from possible_nodes
    selected_nodes = Set.new
    max_tau = @taus.values.max
    possible_nodes.each {|n|
      p = (1 + @taus[n.node_id])/max_tau
      if @random.rand < p
        selected_nodes.add n
      end
    }

    # Bit of debugging output
    if DEBUG and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes
  end

  def select_step_from possible_nodes
    selected_nodes = Set.new
    possible_nodes.each {|n|
      # p = (1 + @taus[n.node_id])/max_tau
      if @taus[n.node_id] > @step_epsilon
        selected_nodes.add n
      else
        if @random.rand < @step_eta
          selected_nodes.add n
        end
      end
    }

    # Bit of debugging output
    if Simulator::DEBUG and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes

  end

  def select_all_from possible_nodes
    selected_nodes = Set.new possible_nodes

    # Bit of debugging output
    if DEBUG and @node_id == 0
      print_selected_nodes 0, selected_nodes
    end

    selected_nodes

  end

  def print_selected_nodes id, selected_nodes

    if @node_id == 0
      print "Node #{id} selected:"
      selected_nodes.each { |n|
        print " #{n.node_id}"
      }
      puts
    end

  end


end
