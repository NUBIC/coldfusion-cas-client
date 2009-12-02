require File.dirname(__FILE__) + '/../test_helper'
require 'access_controller'
require 'mocha'

# Re-raise errors caught by the controller.
class AccessController; def rescue_action(e) raise e end; end

class AccessControllerTest < ActionController::TestCase  
  def setup
    @controller = AccessController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    Bcsec.configure {
      portal         :port
      app_name       :cantina
      authenticator  :mock
    }
    @auth = Bcsec.authenticators[0]
    @auth.valid_credentials!("jo", "pass", :port)

    @cas_client = stub_everything('CAS client')
    Bcsec.cas_client = nil

    class << @controller
      # helper method convenience accessor; backported from Rails 2.2.0
      def helpers
        unless @helper_proxy
          @helper_proxy = ActionView::Base.new
          @helper_proxy.extend master_helper_module
        else
          @helper_proxy
        end
      end
    end
  end

  def test_get_login_form
    get :login
    assert_response :success
  end

  def test_valid_login
    post :login, { :username => 'jo', :password => 'pass' }
    assert_response :redirect
    assert_equal @auth.users['jo'], session[:bcsec_user]
    assert_redirected_to @controller.login_target
  end
  
  def test_invalid_login
    post :login, { :username => 'jo', :password => 'poss' }
    assert_response 401
  end
  
  def test_logout
    get :logout
    assert_response :redirect
    assert_redirected_to @controller.logout_target
    # can't test that the session is reset, apparently
  end

  def test_cas_login_redirects_to_cas_server_login_url
    @cas_client.expects(:add_service_to_login_url).with('http://test.host/logged_in').returns('http://cas.example.com')
    Bcsec.cas_client = @cas_client

    get :login

    assert_redirected_to 'http://cas.example.com'
  end

  def test_cas_login_does_not_accept_post
    Bcsec.cas_client = @cas_client

    post :login, { :username => 'jo', :password => 'pass' }

    assert_response 400
  end

  def test_cas_logout_target_is_cas_client_logout_url
    @cas_client.expects(:logout_url).returns('http://cas.example.com/logout')
    Bcsec.cas_client = @cas_client

    get :logout

    assert_redirected_to 'http://cas.example.com/logout'
  end

  def test_current_user_returns_bcsec_user_in_session
    get :login  # primes the session

    user = mock('bcsec user')
    session[:bcsec_user] = user

    assert_equal user, @controller.send(:current_user)
  end

  def test_current_user_prioritizes_cas_proxy_user
    user = mock('bcsec user')
    @controller.instance_variable_set(:@bcsec_cas_proxy_user, user)
    assert_equal user, @controller.send(:current_user)
  end

  def test_current_user_is_helper_method
    assert @controller.helpers.respond_to?(:current_user)
  end
end
