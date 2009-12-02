class WhoamiController < ApplicationController
  def show
    @username = 
      if session[:bcsec_user]
        session[:bcsec_user].username
      elsif @bcsec_cas_proxy_user
        @bcsec_cas_proxy_user.username
      else
        'NO USER SET!!!'
      end
    respond_to do |format|
       format.html 
       format.xml  { render :xml => "<?xml version=\"1.0\" ?><user><name>#{@username}</name></user>" }
     end    
  end  
end
