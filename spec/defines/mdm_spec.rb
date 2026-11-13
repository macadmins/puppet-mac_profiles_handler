# frozen_string_literal: true

require 'spec_helper'
require 'digest/sha1'
require 'json'

describe 'mac_profiles_handler::mdm' do
  let(:title) { 'biz.airbnb.test' }
  let(:mobileconfig) { "<?xml version=\"1.0\"?>\n<plist><dict><key>A</key><string>1</string></dict></plist>\n" }
  # uuid.uuid5(uuid.NAMESPACE_DNS, mobileconfig) -- what MDMDirector installs.
  let(:hashed) { uuid5(mobileconfig) }
  let(:udid) { 'ABCDEF01-2345-6789-ABCD-EF0123456789' }
  let(:installed_uuid) { hashed }
  let(:profiles) { { title => { 'uuid' => installed_uuid } } }
  let(:facts) do
    {
      'mdmenrollment' => { 'mdm_enrolled' => true, 'dep_enrolled' => true },
      'profiles' => profiles,
      'system_profiler' => { 'hardware_uuid' => udid },
    }
  end
  let(:params) { { file_source: mobileconfig, ensure: 'present', type: 'template' } }
  let(:http) { instance_double(Net::HTTP) }

  def uuid5(str)
    b = Digest::SHA1.digest(['6ba7b8109dad11d180b400c04fd430c8'].pack('H*') + str.b).bytes[0, 16]
    b[6] = (b[6] & 0x0f) | 0x50
    b[8] = (b[8] & 0x3f) | 0x80
    h = b.pack('C*').unpack1('H*')
    "#{h[0, 8]}-#{h[8, 4]}-#{h[12, 4]}-#{h[16, 4]}-#{h[20, 12]}"
  end

  def ok(status)
    resp = Net::HTTPOK.new('1.1', '200', 'OK')
    allow(resp).to receive(:body).and_return(JSON.dump([{ 'profile_metadata' => [{ 'status' => status }] }]))
    resp
  end

  before(:each) do
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:read_timeout=)
  end

  context 'when the device already has this exact content installed' do
    it 'does not call MDMDirector' do
      expect(http).not_to receive(:request)
      is_expected.to compile
    end

    context 'with the installed UUID in upper case' do
      let(:installed_uuid) { hashed.upcase }

      it 'still skips' do
        expect(http).not_to receive(:request)
        is_expected.to compile
      end
    end
  end

  # The skip is only safe if every content change is detected. Each case
  # renders different bytes while the device still reports the old UUID, so
  # it must POST. Distinct titles: rspec-puppet caches catalogs by inputs.
  {
    'a changed value' => ->(s) { s.sub('<string>1</string>', '<string>2</string>') },
    'one added byte' => ->(s) { s + ' ' },
    'a trailing newline removed' => ->(s) { s.chomp },
    'whitespace only' => ->(s) { s.sub('<dict>', "<dict>\n\t") },
    'a key case change' => ->(s) { s.sub('<key>A</key>', '<key>a</key>') },
  }.each_with_index do |(desc, mutate), i|
    context "when the rendered content differs by #{desc}" do
      let(:title) { "biz.airbnb.test.changed#{i}" }
      let(:installed_uuid) { uuid5(mobileconfig) }
      let(:params) { { file_source: mutate.call(mobileconfig), ensure: 'present', type: 'template' } }

      it 'POSTs the new content' do
        expect(params[:file_source]).not_to eq(mobileconfig)
        expect(http).to receive(:request).with(an_instance_of(Net::HTTP::Post)).and_return(ok('pushed'))
        is_expected.to compile
        is_expected.to contain_notify("#{title} was pushed to #{udid}")
      end
    end
  end

  context 'when the device reports no UUID for the identifier' do
    let(:title) { 'biz.airbnb.test.nouuid' }
    let(:installed_uuid) { nil }

    it 'POSTs it' do
      expect(http).to receive(:request).with(an_instance_of(Net::HTTP::Post)).and_return(ok('pushed'))
      is_expected.to compile
    end
  end

  context 'when the profile is not installed' do
    let(:title) { 'biz.airbnb.test.missing' }
    let(:profiles) { {} }

    it 'POSTs it' do
      expect(http).to receive(:request).with(an_instance_of(Net::HTTP::Post)).and_return(ok('pushed'))
      is_expected.to compile
    end
  end

  context 'when the profiles fact is missing' do
    let(:title) { 'biz.airbnb.test.nofact' }
    let(:facts) { super().reject { |k, _| k == 'profiles' } }

    it 'POSTs it instead of failing to compile' do
      expect(http).to receive(:request).with(an_instance_of(Net::HTTP::Post)).and_return(ok('pushed'))
      is_expected.to compile
    end
  end

  context 'when the same content is installed under a different identifier' do
    let(:title) { 'biz.airbnb.test.other' }
    let(:profiles) { { 'biz.airbnb.somethingelse' => { 'uuid' => hashed } } }

    it 'POSTs it' do
      expect(http).to receive(:request).with(an_instance_of(Net::HTTP::Post)).and_return(ok('pushed'))
      is_expected.to compile
    end
  end

  context 'when ensure is absent and the profile is installed' do
    let(:title) { 'biz.airbnb.test.absent' }
    let(:params) { { file_source: mobileconfig, ensure: 'absent', type: 'template' } }

    it 'DELETEs it even though the content matches' do
      expect(http).to receive(:request).with(an_instance_of(Net::HTTP::Delete)).and_return(ok('deleted'))
      is_expected.to compile
      is_expected.to contain_notify("#{title} was deleted from #{udid}")
    end
  end
end
