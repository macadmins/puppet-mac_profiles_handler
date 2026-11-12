# frozen_string_literal: true

require 'digest/sha1'

# mac_profiles_handler::hashed_payload_uuid
#
# The PayloadUUID MDMDirector gives a profile before it pushes it:
# UUIDv5(NameSpaceDNS, <the mobileconfig bytes POSTed>), lowercase. MDMDirector
# rewrites the profile's top-level PayloadUUID to this value (director/profile.go,
# `uuid.NewSHA1(uuid.NameSpaceDNS, mobileconfig)`), so once a device has the
# profile installed, $facts['profiles'][<id>]['uuid'] equals this value.
#
# mac_profiles_handler::mdm compares the two to skip the POST to MDMDirector
# when the device already has exactly this content installed.
#
# @return [String] lowercase UUID, e.g. "0b7c8e4a-...".
Puppet::Functions.create_function(:'mac_profiles_handler::hashed_payload_uuid') do
  dispatch :hashed_payload_uuid do
    param 'String', :mobileconfig
    return_type 'String'
  end

  def hashed_payload_uuid(mobileconfig)
    # RFC 4122 NameSpace_DNS, 6ba7b810-9dad-11d1-80b4-00c04fd430c8. A local,
    # not a constant: constants in a create_function block land on a shared
    # Puppet class and are redefined on every environment reload.
    namespace_dns = ['6ba7b8109dad11d180b400c04fd430c8'].pack('H*')
    bytes = Digest::SHA1.digest(namespace_dns + mobileconfig.b).bytes[0, 16]
    bytes[6] = (bytes[6] & 0x0f) | 0x50 # version 5
    bytes[8] = (bytes[8] & 0x3f) | 0x80 # RFC 4122 variant
    hex = bytes.pack('C*').unpack1('H*')
    "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
  end
end
