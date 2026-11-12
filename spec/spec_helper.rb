# frozen_string_literal: true

# Plain rspec-puppet (no puppetlabs_spec_helper), same as local_modules/screensaver.
require 'rspec-puppet'

fixture_path = File.expand_path('fixtures', __dir__)
RSpec.configure do |c|
  c.mock_with :rspec
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest = File.join(fixture_path, 'manifests', 'site.pp')
  c.environmentpath = fixture_path
  c.hiera_config = File.join(fixture_path, 'hiera', 'hiera.yaml')
end
