Puppet::Type.type(:profile_manager).provide :osx do
  desc "Provides management of mobileconfig profiles on OS X."

  confine :operatingsystem => :darwin

  defaultfor :operatingsystem => :darwin

  commands :profilescmd => '/usr/bin/profiles'

  def create
    profilescmd('-I', '-F', resource[:profile])
  end

  def destroy
    profilescmd('-R', '-p', resource[:name])
  end

  def exists?
    if Facter.value(:profiles).include? resource[:name]
      return true
    else
      return false
    end
  end
end
