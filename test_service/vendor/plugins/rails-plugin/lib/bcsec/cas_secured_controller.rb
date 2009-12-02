require 'bcsec/secured_controller'
require 'bcsec/user'
require 'bcsec/rails_cas_filter'

module Bcsec::CasSecuredController
  include Bcsec::BcsecSecuredController

  attr_reader :bcsec_cas_proxy_user

  def self.included(controller_class)
    controller_class.class_eval do
      include Bcsec::AuthorizationHandler
      prepend_before_filter Bcsec::RailsCasFilter, :bcsec_authorize
      helper 'bcsec/authorization'
      helper_method :current_user
    end
  end
end
