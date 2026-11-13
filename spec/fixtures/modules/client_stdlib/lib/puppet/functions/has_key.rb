# frozen_string_literal: true

# Spec stub of stdlib's has_key, which mac_profiles_handler::mdm uses.
Puppet::Functions.create_function(:has_key) do
  def has_key(hash, key)
    # Match stdlib: raise on a non-hash instead of returning false.
    raise ArgumentError, 'has_key(): expects the first argument to be a hash' unless hash.is_a?(Hash)

    hash.key?(key)
  end
end
