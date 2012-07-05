# Here is some more reasoning about the architectural issues relating to where
# ensembles and bandit solvers go.
#
# Bandit solvers fit nicely into the architecture, as the meta block switches
# functionally equivalent strategies in and out of use in the self-expression
# block. But, the current architectural separation between the meta block and
# self-expression doesn't quite capture ensembles. Where is the expression /
# action selection decision taking place in these cases? It should still be in
# the self-expression block (i.e. we should be able to disable the meta block
# and the system continues to function, albeit with reduced adaptivity.)
# So, ensembles must fit in the self-expression block. Are they qualitatively
# different from bandit solvers to switch strategies then?
#
# Okay - with bandits, it's only the switching part that is related to
# meta-self-awareness. This is the adaptive learning part.
# With ensembles, a simple static blended strategy would not involve meta
# self-awareness, it could be hard coded as a self-expressive strategy itself.
# Where the meta-self-awareness comes in is in the updating of the ensemble's
# weights, or adding and removing baseline strategies from the ensemble.
#
# So, the self-expression block should provide a simple "ensemble" strategy
# (or strategies), which blends multiple strategies together. Examples of this
# could be: majority voting, union / intersection, etc.
#
# We then need, in the meta block, some learning which modifies these
# ensembles during runtime, e.g. by updating weights.


class Self_Expression_Engine

  def initialize random, debug
    @random = random
    @debug = debug
  end

  def enable_capability capability
    require "neighbourhood-selection/self_expression/capabilities/#{capability.downcase}"
    self.extend Module::const_get(capability)

    # Modules can include an initialize_capabilityname method
    if self.respond_to? "initialize_#{capability.downcase}"
      self.method("initialize_#{capability.downcase}").call
    end
  end


  # Tell this self-expression engine where to get its self information from.
  def set_self_awareness_source source
    @self_awareness = source
  end


  # Select which strategy from the enabled portfolio the engine will actually
  # use.
  def set_strategy new_strategy
    # TODO: Some error checking here - check the method exists.
    @selection_strategy = new_strategy
  end

  # Wrapper method to access @self_awareness (i.e. with self.awareness)
  def awareness
    @self_awareness
  end

  # Select and return the relevant neighbourhood, according to the currently set
  # strategy.
  #
  # The strategy currently in @communication_strategy must exist as a method.
  # In the new framework, this method will actually do the message sending.
  def select_relevant_neighbourhood
    begin
      method(@selection_strategy).call
    rescue => e
      warn "Warning: The neighbourhood selection strategy generated an exception of type #{e.class}."
      warn "--> #{e}"
      warn "--> The strategy #{@selection_strategy} either did not exist or work properly."
      warn "--> This node will select *no nodes*."
      Set.new
    end
  end

  # should this engine output debugging info?
  def debug?
    @debug
  end

  # should this engine output debugging info?
  def random
    @random
  end

end
