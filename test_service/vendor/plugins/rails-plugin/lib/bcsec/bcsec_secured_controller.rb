module Bcsec::BcsecSecuredController
  def self.included(controller_class)
    if [:before_filter, :helper].all? { |m| controller_class.respond_to?(m) }
      controller_class.class_eval do
        include Bcsec::AuthorizationHandler
        before_filter :bcsec_authorize
        helper 'bcsec/authorization'
        helper_method :current_user
      end
    end
  end
  
  protected
  
  def bcsec_authorize
    logger.debug "Current user: #{current_user.inspect}"
    if current_user.nil?
      if bcsec_mime_types_for_basic_auth.include?(request.format)
        if user = authenticate_with_http_basic { |u, p| Bcsec.valid_credentials?(u, p) }
          session[:bcsec_user] = user
        else
          return request_http_basic_authentication(Bcsec.app_name.to_s)
        end
      else
        session[:requested_params] = params
      
        redirect_to login_url
        return false
      end
    end
    
    unless bcsec_allow?
      # TODO: make this an application-replaceable view
      render :text => "Forbidden", :status => 403
      return false
    end
  end
  
  def bcsec_mime_types_for_basic_auth
    [Mime::JSON, Mime::YAML]
  end
  
  # Verifies that the user allowed to access the page on a coarse-grained level.
  # Provides a hook for non-group-based authorization.  Group-based authorization
  # is provided in detail by Bcsec::AuthorizationHandler.
  def bcsec_allow?
    current_user.may_access?(Bcsec::portal)
  end
end
