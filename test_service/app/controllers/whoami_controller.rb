class WhoamiController < ApplicationController
  def show
    @username = session[:bcsec_user].username
    respond_to do |format|
       format.html 
       format.xml  { render :xml => "<?xml version=\"1.0\" ?><user><name>#{@username}</name></user>" }
     end    
  end  
end
