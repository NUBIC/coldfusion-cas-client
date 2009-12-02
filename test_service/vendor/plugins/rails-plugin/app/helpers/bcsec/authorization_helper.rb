module Bcsec::AuthorizationHelper
  def self.included(base)
    self.setup_permit_helpers
  end
  
  def permit(*groups, &content)
    yield if controller.permit groups
  end
  
  def self.setup_permit_helpers
    groups = 
      begin
        Bcsec::all_groups
      rescue Bcsec::ConfigurationError => e
        Rails::logger.warn("Trouble setting up permit helpers: #{e}")
        []
      end
    groups.map { |node| node.name }.each do |g|
      group_name = g.downcase

      self.send :module_eval, <<-end_eval
        def #{group_name}_content(&content)
          yield if controller.permit :#{group_name}
        end
      end_eval
    end
  end
end