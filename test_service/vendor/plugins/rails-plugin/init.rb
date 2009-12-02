gem 'bcsec'
require 'bcsec'
require 'bcsec/models'
require 'bcsec/user'
require 'bcsec/authenticators'
require 'bcsec/rlogin'
require 'bcsec/central_authentication_parameters'

if Object.const_defined?(:Rails) && File.directory?( File.join(Rails.root, "public") )
  # Copy assets
  STYLESHEETS_DIRECTORY = File.join(Rails.root, "public", "plugin_assets", "bcsec", "stylesheets")
  unless File.exists?( File.join(STYLESHEETS_DIRECTORY, "bcsec.css") )
    source = File.dirname(__FILE__) + "/assets/stylesheets"
    FileUtils.mkdir_p(STYLESHEETS_DIRECTORY)
    FileUtils.cp(Dir.glob(source+'/*.*'), STYLESHEETS_DIRECTORY)
  end
end