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
end
