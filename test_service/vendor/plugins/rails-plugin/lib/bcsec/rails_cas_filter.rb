require 'casclient/frameworks/rails/filter'

class Bcsec::RailsCasFilter
  class << self
    CASFilter = CASClient::Frameworks::Rails::Filter

    def filter(controller)
      configure unless cas_client_configured?
      success = CASFilter.filter(controller)
      login_user(controller) if success
    end
    
    def configure
      client = Bcsec.cas_client
      CASFilter.send(:class_variable_set, :@@client, client)
      CASFilter.send(:class_variable_set, :@@config, Bcsec.cas_parameters)
      CASFilter.send(:class_variable_set, :@@log, client.log)
    end
    
    private

    def cas_client_configured?
      !CASFilter.client.nil?
    end

    def login_user(controller)
      user = bcsec_user(controller)
      if received_proxy_ticket?(controller)
        controller.instance_variable_set(:@bcsec_cas_proxy_user, user)
        Bcsec.amplify!(user)
      else
        if !controller.session[:bcsec_user]
          Bcsec.amplify!(user)
          controller.session[:bcsec_user] = user 
        end
      end
    end

    def received_proxy_ticket?(controller)
      ticket = controller.params[:ticket]
      ticket =~ /^PT-/ if ticket
    end

    def bcsec_user(controller)
      Bcsec::User.new(controller.session[CASFilter.client.username_session_key])
    end
  end
end
