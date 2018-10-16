# Hacker News Reader

## Installation

You want to `bundle install` of course.

Next, check out the `lib/config.rb` file. You'll see some things you
have to setup:

**Setup Postgres**

Setup your Postgres db. You can use my default db name "hacker_news".
But you need to run the `createdb hacker_news` command to make the new
database.

**Setup AWS SES**

You need to setup AWS SES to be able to send emails. They will give you
an AWS SES username and password for their SMTP server.

Put these secrets in a JSON file. An example of this file is in
`examples/secrets.json`. Modify `Config::SECRETS_FILE_PATH` to point to
your version of this file.

Of course, put the email address you want to use in the secrets file,
too!
