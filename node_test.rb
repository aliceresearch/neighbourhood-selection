require "./node.rb"

a = Node.new(1)
b = Node.new(2)
c = Node.new(3)
d = Node.new(4)
e = Node.new(5)
me = Node.new(0)

possible_nodes = Set.new [ a, b, d, e ]
me.step1(possible_nodes)
me.print_taus

possible_nodes.add c
me.step1(possible_nodes)
me.print_taus

possible_nodes.delete a
me.step1(possible_nodes)
me.print_taus
