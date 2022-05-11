# mac_profiles_handler module for Puppet

## Description

This module provides two resource types for interacting with macOS configuration profiles.

The profile_manager resource type is the back-end type that interacts with /usr/bin/profiles for creating, destroying and verifying a resource type. The mac_profiles_handler::manage resource type is user-facing and handles the management of the actual files.

A structured fact is also provided to list installed profiles along with some metadata.

## Usage

> Local profile installation is non-functional on macOS 11 and newer. Use the method => 'mdm' below.

<pre>
mac_profiles_handler::manage { 'com.puppetlabs.myprofile':
  ensure  => present,
  file_source => 'puppet:///modules/mymodule/com.puppetlabs.myprofile.mobileconfig',
}
</pre>

You can use an ERB template instead of a mobileconfig:

<pre>
mac_profiles_handler::manage { 'com.puppetlabs.myprofile':
  ensure  => present,
  file_source => template('mymodule/com.puppetlabs.myprofile.erb'),
  type => 'template',
}
</pre>

You can also ensure that a profile is absent by specifying just the identifier:

<pre>
mac_profiles_handler::manage { '00000000-0000-0000-A000-4A414D460003':
  ensure => absent,
}
</pre>

You must pass the profilers identifier as your namevar, ensure accepts present or absent and file_source behaves the same way source behaves for file.

### Profile installation via MicroMDM and MDMDirector

Profiles can be sent via MDMDirector and compatible tools. Add your configuration to Hiera (`eyaml` recommended for secrets).

<pre>
# MDMDirector information
mac_profiles_handler::mdmdirector_host: https://mdmdirector.company.com
mac_profiles_handler::mdmdirector_password: secret
mac_profiles_handler::mdmdirector_username: mdmdirector
# Install all profiles via MDM
mac_profiles_handler::method: mdm
</pre>


You can install profiles with a mobileconfig file in the module or an ERB template.

<pre>
mac_profiles_handler::manage { 'com.puppetlabs.myprofile':
  ensure  => present,
  file_source => 'puppet:///modules/mymodule/com.puppetlabs.myprofile.mobileconfig',
  method => 'mdm'
}
</pre>

<pre>
mac_profiles_handler::manage { 'com.puppetlabs.myprofile':
  ensure  => present,
  file_source => template('mymodule/com.puppetlabs.myprofile.erb'),
  type => 'template',
  method => 'mdm'
}
</pre>

When ensuring a profile is removed, you must also provide the file_source and method.

<pre>
mac_profiles_handler::manage { 'com.puppetlabs.myprofile':
  ensure  => absent,
  file_source => template('mymodule/com.puppetlabs.myprofile.erb'),
  type => 'template',
  method => 'mdm'
}
</pre>

## Dependencies

- [puppetlabs/stdlib >= 2.3.1](https://forge.puppetlabs.com/puppetlabs/stdlib)
- Puppet >= 4.4.0 for `puppet/util/plist`, for earlier versions use d13469a.

## To-Do

Improve provider parsing.
Handle more types of configuration profiles.
Improve documentation when author isn't presenting the next morning.

## Contributing

Please do!
Create issues in GitHub, Make Pull Requests, Have Fun!
