class AccessController < ActionController::Base
  include Bcsec::CurrentUser
  
  skip_before_filter :bcsec_authorize
  
  filter_parameter_logging :password

  # TODO: find a good way to test this
  before_filter(:except => [:login, :logout, :rlogout,:rlogin]) do |controller|
    if controller.send(:using_cas?)
      Bcsec::RailsCasFilter.filter(controller)
    else
      true
    end
  end

  helper_method :current_user
  
  def login
    if using_cas? 
      cas_login
    else
      bcsec_login
    end
  end
  
  def logout
    reset_session
    redirect_to logout_target
  end
  
  def rlogin
    # forwarded_state = Bcsec::rlogin_handler.receive(params[:key])
    forwarded_state = Pers::Rlogin.receive(params[:key])
    route = forwarded_state.variables.delete('named_route')
    options = forwarded_state.variables.to_hash
    process_rlogin_options!(options)
    
    logger.debug("forwarded_state: #{forwarded_state.inspect}")
    logger.debug("route: #{route.inspect}")
    logger.debug("options: #{options.inspect}")
    
    # This should probably be done differently
    user = Pers::Person.find_by_username(forwarded_state.username).to_user
    
    unless user
      flash[:error] = "Login failed"
      render :status => 401
    else
      Bcsec::amplify!(user)
      session[:bcsec_user] = user
      if route
        redirect_to send(:"#{route}_url", options)
      elsif options.has_key('controller')
        redirect_to options
      else
        raise "Rlogin did not specify a redirection target"
      end
    end
  end
  
  def rlogout
    target_name = params.delete :target_name
    target = Bcsec::rlogin_targets[target_name.to_sym]
    unless target
      msg = "<h1>Rlogout failure</h1><p>Unknown rlogout target #{target_name}."
      if Bcsec.rlogin_targets.empty?
        msg += " Did you set a value for Bcsec::rlogin_targets?"
      else
        msg += " Known: #{Bcsec::rlogin_targets.keys.inspect}."
      end
      render :text => msg, :status => 400
      return
    end
    
    # state = Bcsec::rlogin_handler.new
    state = Pers::Rlogin.new
    state.target_portal = target.portal
    state.username = current_user.username
    state.ip = request.remote_ip
    
    additional_rlogout_variables.each_pair { |k, v| state.variables[k] = v }
    target.convert_params(state, params)
    
    key = state.forward!
    
    logger.debug "rlogin state: #{state.inspect}"
    logger.debug "variables: #{state.variables.to_hash.inspect}"
    
    redirect_to "#{target.entry_url}?key=#{key}"
  end
  
  # Create route for login_target to specify where to redirect
  # on a successful login.
  LOGIN_TARGET = :login_target
  def login_target #:doc
    default_target = { :action => 'logged_in' }
    
    ActionController::Routing::Routes.named_routes.get(LOGIN_TARGET) ? url_for(LOGIN_TARGET) : default_target    
  end
  
  # Override this method to specify the target to which to redirect
  # on a successful logout.
  #
  # The default is the login page.
  def logout_target #:doc
    if using_cas?
      cas_logout_target
    else
      { :action => 'login' }
    end
  end
  
  # Process the variables received during an rlogin.
  #
  # Default is no action.
  def process_rlogin_options!(options)
    
  end
  
  # Override this method to insert additional values into the variables
  # struct on rlogout (beyond those passed in the URL).  It should return a 
  # hash or duck-similar object.
  #
  # Default is an empty hash
  def additional_rlogout_variables
    { }
  end

  private

  def using_cas?
    Bcsec.cas_client
  end

  def bcsec_login
    if request.post?
      user = Bcsec::valid_credentials?(
          params[:username], params[:password])
      unless user
        flash[:error] = "Login failed"
        render :status => 401
      else
        session[:bcsec_user] = user
        
        if session[:requested_params]
          redirect_to session[:requested_params]
        else
          redirect_to login_target
        end
      end
    else
      render
    end
  end

  def cas_login
    if request.get?
      next_url = session[:requested_params] ? session[:requested_params] : url_for(login_target)
      redirect_to Bcsec.cas_client.add_service_to_login_url(next_url)
    else
      render :nothing => true, :status => 400
    end
  end
  
  def cas_logout_target
    Bcsec.cas_client.logout_url(request.referer, login_url)
  end
end
