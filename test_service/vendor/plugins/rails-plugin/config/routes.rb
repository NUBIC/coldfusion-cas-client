ActionController::Routing::Routes.draw do |map|
  map.login "/login", :controller => 'access', :action => 'login'
  map.logout "/logout", :controller => 'access', :action => 'logout'
  map.logged_in "/logged_in", :controller => 'access', :action => 'logged_in'

  map.rlogin "/rlogin/:key", :controller => 'access', :action => 'rlogin'
  map.rlogin "/rlogin", :controller => 'access', :action => 'rlogin'
  map.rlogout "/rlogout/:target_name/*target_url", :controller => 'access', :action => 'rlogout'
end