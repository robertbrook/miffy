# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_miffy_session',
  :secret      => '56865e894b3c9b3706947ee3f37fdcaca506fbf1fded1c4803dc34cf15a16b58eb1ca65e0e371b506e253291bbb3c556e2a71955f4463be722860ae5441a7a28'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
