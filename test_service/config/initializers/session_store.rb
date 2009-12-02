# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_test_service_session',
  :secret      => '024f65a516ef24cfb11a36e6fa1f5be2a8f431616379e1e9c25720c262c13e0cfa3c138d24a6f5b6243d705804b402b7d549076da6e38aaa392a379ad82223aa'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
