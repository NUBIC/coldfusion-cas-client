require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/bcsec/cas_secured_controller'
require File.dirname(__FILE__) + '/../controller_module_common_setup'

class CasSecuredControllerTest < Test::Unit::TestCase
  include ControllerModuleCommonSetup

  def setup
    super
    Bcsec::configure do
      Bcsec.cas_parameters = { :cas_base_url => 'foo' }
      use_cas
    end
    @controller.class.send(:include, Bcsec::SecuredController)
  end
  
  def teardown
    Bcsec::configure do
      clear
    end
  end

  def test_current_user_is_settable_via_proxy_user
    user = Bcsec::User.new('testuser')
    @controller.instance_variable_set(:@bcsec_cas_proxy_user, user)

    assert_equal user, @controller.send(:current_user)
  end

  def test_current_user_uses_user_in_session_as_fallback
    user = Bcsec::User.new('testuser')

    @controller.instance_variable_set(:@bcsec_cas_proxy_user, nil)
    @controller.instance_eval do
      session[:bcsec_user] = user
    end

    assert_equal user, @controller.send(:current_user)
  end

  def test_cas_filter_setup
    expected_order = [Bcsec::RailsCasFilter, :bcsec_authorize]

    filter_chain = @controller.class.filter_chain
    assert_equal expected_order, filter_chain.map { |f| f.method }
  end

  def test_current_user_is_exposed_as_helper_method
    assert @controller.respond_to?(:current_user)
  end
end
