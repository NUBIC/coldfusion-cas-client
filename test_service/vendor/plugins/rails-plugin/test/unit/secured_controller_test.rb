require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/bcsec/secured_controller'
require File.dirname(__FILE__) + '/../controller_module_common_setup'

class SecuredControllerTest < Test::Unit::TestCase
  include ControllerModuleCommonSetup

  def setup
    super
    @controller.class.send(:include, Bcsec::SecuredController)
  end

  def test_only_activates_before_filters_when_included_into_controller
    assert @controller.class.filter_chain.include?(:bcsec_authorize)

    other_object = Object.new
    other_object.class.send(:include, Bcsec::SecuredController)
  end

  def test_current_user_returns_session_bcsec_user
    user = Bcsec::User.new('testuser')
    @controller.session[:bcsec_user] = user

    assert_equal user, @controller.send(:current_user)
  end
  
  def test_current_user_is_exposed_as_helper_method
    assert @controller.respond_to?(:current_user)
  end

  def test_uses_cas_secured_controller_when_cas_client_is_enabled
    Bcsec.cas_client = true

    new_controller = make_controller
    new_controller.class.send(:include, Bcsec::SecuredController)

    assert new_controller.class.ancestors.include?(Bcsec::CasSecuredController)
  end
end
