# This is a holding class for self-awareness capability modules.
class Self_Awareness_Capability

  def initialize capability, engine, random, debug
    @random = random
    @debug = debug

    # The engine that this capability belongs to.
    # Used for accessing other capabilities of the node's self-awareness. 
    @engine = engine

    cap = capability.to_s

    require "neighbourhood-selection/self_awareness/capabilities/#{capability.downcase}"
    self.extend Module::const_get(capability)

    # Modules can include an initialize_capabilityname method
    if self.respond_to? "initialize_#{capability.downcase}"
      self.method("initialize_#{capability.downcase}").call
    end

  end

  # Allow access to other aspects of the node's self awareness
  # (i.e. through self.awareness)
  def awareness
    @engine
  end

  # Should this capability output debugging info?
  def debug?
    @debug
  end

end
