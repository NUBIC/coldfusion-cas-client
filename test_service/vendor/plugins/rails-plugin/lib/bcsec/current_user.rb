module Bcsec::CurrentUser
  def current_user
    @bcsec_cas_proxy_user || session[:bcsec_user]
  end
end