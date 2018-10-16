module HackerNewsReader; end

module HackerNewsReader::Config
  # Useful for debugging. Will print more info about what the script is
  # doing.
  FETCH_LOGGING = false
  # I don't want to send an email with the stories until a critical mass
  # of interesting stories builds up.
  MIN_EMAIL_LENGTH = 10
  # Wait 1hr before refreshing a story. Limits the number of API calls.
  SECONDS_BEFORE_REFRESH = 60 * 60.0
  # I use AWS SES. My credentials are stored in a secrets file. If I
  # checked that file in, people could steal the secrets and spam
  # everyone.
  SECRETS_FILE_PATH = "/Users/ruggeri/.secrets.json"
  # And this is the email server URL. You may need a different one.
  AWS_EMAIL_SERVER_URL = "email-smtp.us-west-2.amazonaws.com"
  # This is the address that will receive your HN emails.
  EMAIL_ADDRESS = "ruggeri@self-loop.com"
end
