# Load the normal Rails helper. This ensures the environment is loaded
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Allow silencing to be disabled to monitor fixture loading
module ActiveRecord
  class Base
    class << self
      def disableable_silence(&block)
        if allow_quiet?
          original_silence &block
        else
          yield
        end
      end
    
      def allow_quiet?
        # has to be nil check, since the other value is false
        @be_quiet = true if @be_quiet.nil?
        @be_quiet
      end

      attr_writer :allow_quiet
      alias_method :original_silence, :silence unless method_defined?(:original_silence)
      alias_method :silence, :disableable_silence
    end
  end
end

Bcsec::configure { 
  clear 
  app_name :"Pterodactyl Mail"
  portal :"Yabba-dabba-yahoo"
}

# These models are used as fixtures only

class Pers::Group < Pers::Base
  set_table_name "t_security_groups"
end

class Pers::GroupAssociation < Pers::Base
  set_table_name "t_security_group_associations"
end

class Pers::PersonAffiliation < Pers::Base
  set_table_name "t_personnel_affiliations"
end

class ActiveSupport::TestCase

  # Note that the database configuration for these fixtures
  # is derived from the enclosing application.  It will use 
  # whatever configuration Pers::Base.connection returns.
  
  set_fixture_class( 
    :t_security_applications => Pers::Portal,
    :t_security_logins => Pers::Login, 
    :t_personnel => Pers::Person, 
    :t_personnel_affiliations => Pers::PersonAffiliation, 
    :t_security_groups => Pers::Group, 
    :t_security_group_associations => Pers::GroupAssociation,
    :t_security_group_members => Pers::GroupMembership,
    :t_rlogins => Pers::Rlogin
  )
  fixtures :t_personnel, :t_security_applications, :t_security_logins, 
           :t_security_groups, :t_security_group_associations, 
           :t_security_group_members, :t_rlogins, :t_personnel_affiliations
end
