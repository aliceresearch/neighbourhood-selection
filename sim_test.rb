require "./simulator"

taus_file = File.open("sim.taus", 'w')
node_utilities_file = File.open("sim.node_utilities", 'w')
conjoint_utilities_file = File.open("sim.conjoint_utilities", 'w')


sim = Simulator.new "Test"

# Some initial output
if sim.debug?
  puts "Beginning simulation with #{sim.nodes.length} nodes."
  print "Node IDs are:"
  sim.nodes.each { |i|
    print " #{i.node_id}"
  }
  puts "."
end

# Run a number of simulation steps.
# Simulator.step can take a block. If one is passed in, then this is executed at
# the end of each time step.
10000.times do
  sim.step do
    # This block is executed at the end of each time step. It can be used for
    # collecting data and printing it out, for example.

    # We're only really interested in tracking one node, node 0
    interesting_node = sim.nodes.find { |n| n.node_id==0 }

    # Print out the utility and tau associated with each possible node.
    interesting_node.print_taus taus_file
    interesting_node.print_total_utilities node_utilities_file

    # Just print the cumulative conjoint utility so far
    interesting_node.print_cumulative_conjoint_utility conjoint_utilities_file
  end

end

taus_file.close
node_utilities_file.close
conjoint_utilities_file.close
