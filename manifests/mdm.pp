# Installs a profile with MDM
define mac_profiles_handler::mdm (
    $file_source,
    $ensure,
    $type,
) {

  $payload_identifier = $name

  $enrolled = $facts['mdmenrollment']['mdm_enrolled']

  if 'puppet:///modules/' in $file_source {
    $munged_source = inline_template('<%= @file_source[18..-1] %>')
    notify{$munged_source: }
    $input = file($munged_source)
  } else {
    $input = $file_source
  }

  if $enrolled == false {
    notify {"Device is not enrolled in MDM. ${payload_identifier}":
      loglevel => 'err',
    }
  }

  if $enrolled {

    $profiles = $facts['profiles']

    $mdmdirector_host = lookup('mac_profiles_handler::mdmdirector_host', String)
    $mdmdirector_username = lookup('mac_profiles_handler::mdmdirector_username', String)
    $mdmdirector_password = lookup('mac_profiles_handler::mdmdirector_password', String)


    $mdmdirector_path = lookup('mac_profiles_handler::mdmdirector_path', String, 'first', '/profile')
    $udid = $facts['system_profiler']['hardware_uuid']

    $output = send_mdm_profile(
      $input,
      $udid,
      $payload_identifier,
      $ensure,
      $mdmdirector_username,
      $mdmdirector_password,
      $mdmdirector_host,
      $mdmdirector_path,
      )

      $error = $output['error']
      $error_message = $output['error_message']
      if $error {
        notify{"Error pushing ${name}: ${error_message}":
          loglevel => 'err',
        }
      } else {
        # Does mdmdirector know about this profile?
        if $output['output'][0]['profile_metadata'] != undef {
          $status = $output['output'][0]['profile_metadata'][0]['status']
          if $status == 'pushed' {
            notify{"${name} was pushed to ${udid}": }
          }

          if $status == 'deleted' {
            notify{"${name} was deleted from ${udid}": }
          }

        if $facts['mdmenrollment']['dep_enrolled'] == false {
          if $ensure == 'absent' and has_key($profiles, $payload_identifier){
            exec { "remove ${payload_identifier}":
                command => "/usr/bin/profiles -R -p ${payload_identifier}",
                returns => [0,1]
            }
          } else {
            if has_key($profiles, $payload_identifier){
              $new_hash = $output['output'][0]['profile_metadata'][0]['hashed_payload_uuid']
              if $profiles[$payload_identifier]['uuid'] != $new_hash {
                exec { "remove ${payload_identifier}":
                    command => "/usr/bin/profiles -R -p ${payload_identifier}",
                    returns => [0,1]
                }
              }
            }
          }
        }
        } else {
          notify{"MDMDirector did not return expected output for ${name}":
            loglevel => 'err',
          }
        }

    }
  }

}
