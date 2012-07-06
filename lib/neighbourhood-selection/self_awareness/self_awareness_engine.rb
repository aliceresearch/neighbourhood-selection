# TODO: When passing through methods to capabilities, force them to be prefixed
# with either notify_ or retrieve_, by adding that to message_name and knowledge
# in this class.


require 'neighbourhood-selection/self_awareness/self_awareness_capability'

class Self_Awareness_Engine

  def initialize random, debug
    @random = random
    @debug = debug

    # A Hash of capability objects.
    @capabilities = {}
  end


  # Enable a capability in this self-awareness engine.
  def enable_capability capability
    if debug?
      puts "Enabling capability: #{capability}"
    end

    # Add a new capability with the given name, and set its engine callback to
    # be this engine.
    @capabilities[capability] = Self_Awareness_Capability.new capability, self, @random, debug?
  end


  # This method receives messages from the node's message handler.
  # It calls the relevant method on all self-awareness capabilities which
  # implement it, to deliver the message and the payload.
  def notify message_name, payload=nil

    if debug?
      puts "Notifying self-awareness capabilities of message #{message_name}, with payload of size #{payload.size}:"
    end

    @capabilities.each do |capability_name, capability|
      if debug?
        print "--> Checking if capability #{capability_name} responds: "
      end

      if capability.respond_to? message_name
        if debug?
          puts "Yes, sending message."
        end
        capability.method(message_name).call payload
      else
        if debug?
          puts "No."
        end
      end
    end
  end


  # Retrieve a particular piece of knowledge from the self-awareness
  # capabilities, if it exists there.
  #
  # TODO: Extend index to multiple arbitrary parameters.
  def retrieve knowledge, index=nil

    if debug?
      puts "Looking up knowledge #{knowledge}:"
    end

    @capabilities.each do |capability_name, capability|
      if debug?
        print "--> Checking in #{capability_name} for knowledge #{knowledge}: "
      end
      if capability.respond_to? knowledge
        if debug?
          puts "Found!"
        end

        # An index is optional
        if index
          return capability.method(knowledge).call index
        else
          return capability.method(knowledge).call
        end

      else
        if debug?
          puts "Not found."
        end
      end
    end

    # If we got here, no capability engine could satisfy the query.
    puts "The self-awareness engine does not have the capability to retrieve #{knowledge}!"
    nil
  end


  # Should this engine output debugging info?
  def debug?
    @debug
  end

end
