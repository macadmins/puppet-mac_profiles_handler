Facter.add(:profiles) do
  confine kernel: "Darwin"
  setcode do
    require "puppet/util/plist"
    require "time"

    profiles = {}

    if Facter.value(:os)["release"]["major"].to_i >= 12
      raw_output = Facter::Util::Resolution.exec(["/usr/bin/profiles", "-C", "-o", "stdout-xml"].join(" "))
      
      # Some debugging profiles can create additional text lines before and after the actual XML
      # Strip any additional text before and after the XML
      xml_output = raw_output
      if raw_output && raw_output.include?("<?xml")
        # Find the start of XML
        xml_start = raw_output.index("<?xml")
        # Find the end of XML
        xml_end = raw_output.rindex("</plist>")
        
        if xml_start && xml_end
          xml_output = raw_output[xml_start..xml_end + "</plist>".length - 1]
        end
      end
      
      plist = Puppet::Util::Plist.parse_plist(xml_output)

      if plist.key?("_computerlevel")
        for item in plist["_computerlevel"]
          profiles[item["ProfileIdentifier"]] = {
            "display_name" => item["ProfileDisplayName"],
            "description" => item["ProfileDescription"],
            "verification_state" => item["ProfileVerificationState"],
            "uuid" => item["ProfileUUID"],
            "organization" => item["ProfileOrganization"],
            "type" => item["ProfileType"],
            "install_date" => DateTime.parse(item["ProfileInstallDate"]),
            "payload" => [],
          }

          for pl in item["ProfileItems"]
            profiles[item["ProfileIdentifier"]]["payload"] << {
              "type" => pl["PayloadType"],
              "identifier" => pl["PayloadIdentifier"],
              "uuid" => pl["PayloadUUID"],
            # commented out for now because its not super useful.
            # 'content' => pl['PayloadContent'],
            }
          end
        end
      end
    end

    profiles
  end
end
