require "./simulator"

s = Simulator.new
# s.nodes.each { |i| 
#   puts i.node_id
# }

100.times {
  s.step
}

# 10.times {
#   puts s.benefit_generator 0.5, 1, 1
# }