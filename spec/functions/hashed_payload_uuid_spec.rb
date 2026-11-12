# frozen_string_literal: true

require 'spec_helper'

# Expected values from Python's uuid.uuid5(uuid.NAMESPACE_DNS, s), which uses the
# same RFC 4122 v5 algorithm as MDMDirector's uuid.NewSHA1(uuid.NameSpaceDNS, b).
describe 'mac_profiles_handler::hashed_payload_uuid' do
  it { is_expected.to run.with_params('').and_return('4ebd0208-8328-5d69-8c44-ec50939c0967') }
  it { is_expected.to run.with_params('hello').and_return('9342d47a-1bab-5709-9869-c840b2eac501') }

  it 'hashes the UTF-8 bytes, as MDMDirector receives them' do
    is_expected.to run.with_params("<?xml version=\"1.0\"?>\n<plist>é</plist>")
                      .and_return('2fa556c8-88c3-5601-b377-04d162700578')
  end
end
