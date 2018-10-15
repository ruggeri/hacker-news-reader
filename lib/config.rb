module HackerNewsReader; end

module HackerNewsReader::Config
  FETCH_LOGGING = false
  MIN_EMAIL_LENGTH = 10
  # Wait 1hr before refreshing a story.
  SECONDS_BEFORE_REFRESH = 60 * 60.0
end
