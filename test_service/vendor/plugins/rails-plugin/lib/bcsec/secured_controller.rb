module Bcsec::SecuredController
  include Bcsec::CurrentUser
  
  def self.included(controller_class)
    if Bcsec.cas_client
      controller_class.send(:include, Bcsec::CasSecuredController)
    else
      controller_class.send(:include, Bcsec::BcsecSecuredController)
    end
  end
end
