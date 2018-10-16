module HackerNewsReader; end

module HackerNewsReader::Config
  # The name of the Postgres database to use. You'll have to have
  # previously called `createdb hacker_news`.
  DB_NAME = "hacker_news"

  # I don't want to send an email with the stories until a critical mass
  # of interesting stories builds up.
  MIN_EMAIL_LENGTH = 10

  # Wait 1hr before refreshing a story. Limits the number of API calls.
  SECONDS_BEFORE_REFRESH = 60 * 60.0

  # I use AWS SES. My credentials are stored in a secrets file. If I
  # checked that file in, people could steal the secrets and spam
  # everyone. You'll need your own.
  #
  # I have an example in `examples/secrets.json`.
  #
  # This expects your secrets file to be in your home directory.
  SECRETS_FILE_PATH = "/Users/#{`whoami`.chomp}/.secrets.json"
end
