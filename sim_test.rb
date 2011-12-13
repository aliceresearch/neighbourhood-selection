require "./simulator"

s = Simulator.new

# Some initial output
puts "Beginning simulation with #{s.nodes.length} nodes."
print "Node IDs are:"
s.nodes.each { |i|
  print " #{i.node_id}"
}
puts "."

# Run a number of simulation steps.
# Simulator.step can take a block. If one is passed in, then this is executed at
# the end of each time step.
10.times {
  s.step do
    s.nodes.find { |n| n.node_id==0 }.print_taus
  end
}

