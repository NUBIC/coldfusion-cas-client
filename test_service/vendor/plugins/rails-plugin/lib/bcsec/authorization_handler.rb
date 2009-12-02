module Bcsec::AuthorizationHandler
  def self.included(base)
    base.extend(ControllerClassMethods)
  end

  def permit(*permitted_groups)
    current_user.in_group?(permitted_groups)
  end
  
  def permit_page_access(*groups)
    unless permit groups
      log_permission_denied 
      render :text => "You don't have permission to access this page", :status => 403
    end
  end
  
  # TODO: generalize this into a plugin-level service
  def log_permission_denied
  end
  
  module ControllerClassMethods
    # Allow class-level authorization check.
    def permit(*groups)
      before_filter do |controller|
        controller.permit_page_access groups
      end
    end
  end
end
