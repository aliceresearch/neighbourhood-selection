class Hash
  # Take a hash and convert any keys that are Strings to symbols.
  # Operates recursively on nested hashes. Any non-String keys are unchanged.
  def self.transform_keys_to_symbols(value)
    return value unless value.is_a?(Hash)
    hash = value.inject({}) do |memo,(k,v)|
      if k.is_a?(String)
        memo[k.to_sym] = Hash.transform_keys_to_symbols(v)
      else
        memo[k] = Hash.transform_keys_to_symbols(v)
      end
      memo
    end
    return hash
  end

  # Take a hash and convert any values that are Strings to symbols.
  # Operates recursively on nested hashes. Any non-String values are unchanged.
  def self.transform_values_to_symbols(value)
    return value unless value.is_a?(Hash)
    hash = value.inject({}) do |memo,(k,v)|
      if v.is_a?(String)
        memo[k] = Hash.transform_values_to_symbols(v.to_sym)
      else
        memo[k] = Hash.transform_values_to_symbols(v)
      end
      memo
    end
    return hash
  end

end
