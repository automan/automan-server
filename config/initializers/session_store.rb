# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_automan-server_session',
  :secret      => '5eff0f033b0f243c735fdb2cf9574bd70d165f852e621940250fbf11e0b230743eb28e1cd10af2214020b3da303a4ddd24fbc5b0f9ed519a5db6137a27900b33'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
