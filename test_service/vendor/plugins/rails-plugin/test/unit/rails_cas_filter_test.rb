require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/bcsec/rails_cas_filter'
require File.dirname(__FILE__) + '/../controller_module_common_setup'
require 'rubycas-client'
require 'mocha'

class RailsCasFilterTest < Test::Unit::TestCase
  include ControllerModuleCommonSetup

  CASFilter = CASClient::Frameworks::Rails::Filter

  def setup
    super
    @filter = Bcsec::RailsCasFilter

    # Some tests are being written before CASClient filter configuration was implemented (TDD, etc.)
    # To make these pass, we need to create a dummy CAS client that responds to CASClient::Client messages
    # but just returns nil for everything.
    CASFilter.send(:class_variable_set, :@@client, stub_everything('dummy client'))

    @controller.params = {}
  end

  def test_filter_delegates_to_cas_filter
    CASFilter.expects(:filter).returns(true)

    @filter.filter(@controller)
  end
  
  def test_filter_should_create_bcsec_user_if_cas_filter_succeeded_and_ticket_is_service_ticket
    @controller.params[:ticket] = 'ST-blah'

    CASFilter.expects(:filter).returns(true)

    @filter.filter(@controller)

    assert_not_nil @controller.session[:bcsec_user]
  end

  def test_filter_should_amplify_bcsec_user_object
    Bcsec.configure do
      amplifier = Class.new do
        def amplify(user); user.group_memberships = :amplified; end
        def valid_credentials?(*args); true; end
      end.new

      authenticators amplifier
    end

    @controller.params[:ticket] = 'ST-blah'

    CASFilter.expects(:filter).returns(true)

    @filter.filter(@controller)

    assert_equal :amplified, @controller.session[:bcsec_user].group_memberships
  end

  def test_filter_should_not_create_bcsec_user_if_cas_filter_succeeded_and_ticket_is_proxy_ticket
    @controller.params[:ticket] = 'PT-blah'

    CASFilter.expects(:filter).returns(true)

    @filter.filter(@controller)

    assert_nil @controller.session[:bcsec_user]
  end

  def test_filter_should_set_bcsec_cas_proxy_user_instance_variable_if_cas_filter_succeeded_and_ticket_is_proxy_ticket
    @controller.params[:ticket] = 'PT-blah'

    CASFilter.expects(:filter).returns(true)

    @filter.filter(@controller)

    assert_not_nil @controller.instance_variable_get(:@bcsec_cas_proxy_user)
  end

  def test_filter_should_not_set_bcsec_cas_proxy_user_instance_variable_if_cas_filter_succeeded_and_ticket_is_service_ticket
    @controller.params[:ticket] = 'ST-blah'

    CASFilter.expects(:filter).returns(true)

    @filter.filter(@controller)

    assert_nil @controller.instance_variable_get(:@bcsec_cas_proxy_user)
  end

  def test_filter_should_not_create_bcsec_user_if_cas_filter_fails
    CASFilter.expects(:filter).returns(false)

    @filter.filter(@controller)

    assert_nil @controller.session[:bcsec_user]
  end

  def test_filter_should_not_set_bcsec_cas_proxy_user_instance_variable_if_cas_filter_fails
    CASFilter.expects(:filter).returns(false)

    @filter.filter(@controller)

    assert_nil @controller.instance_variable_get(:@bcsec_cas_proxy_user)
  end

  def test_filter_should_configure_cas_filter_from_bcsec_object
    client = CASClient::Client.new

    Bcsec.expects(:cas_client).returns(client)

    @filter.configure

    assert_equal client, CASFilter.client
    assert_equal Bcsec.cas_parameters, CASFilter.config
    assert_equal client.log, CASFilter.log
  end
  
  def test_filter_should_use_parameters_from_use_cas
    Bcsec.configure do
      use_cas :service_url => 'foo'
    end
    
    @filter.configure
    
    assert_equal 'foo', CASFilter.config[:service_url]
  end
  
  def test_filter_should_configure_cas_filter_only_once
    CASFilter.send(:class_variable_set, :@@client, nil)

    Bcsec.expects(:cas_client).returns(CASClient::Client.new).once
    CASFilter.stubs(:filter)

    @filter.filter(@controller)
    @filter.filter(@controller)
  end
end
