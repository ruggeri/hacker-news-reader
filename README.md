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

## How to use

**`pull-hacker-news-stories`**

This command will pull new, popular stories from the Hacker News API. It
stores info about these stories in a Postgresql database.

**`review-hacker-news-stories`**

This command will let you review Hacker News stories. It will show you a
story, and you can press `j` to ignore, or `f` to mark as interesting.
You may press `u` to undo.

Hit `Ctr-C` to exit.

**`email-hacker-news-stories`**

This command will send you an email of all stories marked as
interesting. Of course, it will not include any previously emailed
stories!
