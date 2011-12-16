require "./simulator"

taus_file = File.open("sim.taus", 'w')
utilities_file = File.open("sim.utilities", 'w')


s = Simulator.new

# Some initial output
if Simulator::DEBUG
  puts "Beginning simulation with #{s.nodes.length} nodes."
  print "Node IDs are:"
  s.nodes.each { |i|
    print " #{i.node_id}"
  }
  puts "."
end

# Run a number of simulation steps.
# Simulator.step can take a block. If one is passed in, then this is executed at
# the end of each time step.
10.times {
  s.step do
    s.nodes.find { |n| n.node_id==0 }.print_taus taus_file
  end
}

taus_file.close
utilities_file.close
