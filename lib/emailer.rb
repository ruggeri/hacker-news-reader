require 'json'
require 'mail'
require_relative './config.rb'

module HackerNewsReader; end

# Methods that email me the Hacker News update. Meant to be run every
# once in a while so I don't spam myself.
module HackerNewsReader::Emailer
  # I use AWS Simple Email Service. My credentials are stored in a
  # secrets file. If I checked that file in, people could steal the
  # secrets and spam everyone.
  SECRETS = JSON.parse(
    File.read(HackerNewsReader::Config::SECRETS_FILE_PATH),
    symbolize_names: true,
  )

  # Configures the mail gem to use my AWS SES SMTP server.
  Mail.defaults do
    delivery_method :smtp, {
                      address: SECRETS[:AWS_SMTP_SERVER_URL],
                      # Port 587 is used for SMTP over TLS.
                      port: 587,
                      user_name: SECRETS[:SES_USER_NAME],
                      password: SECRETS[:SES_PASSWORD],
                      authentication: :login,
                      enable_starttls_auto: true
                    }
  end

  # Converts an HN item to some HTML with a link.
  def self.item_to_mail_body_line(item)
    hn_url = "https://news.ycombinator.com/item?id=#{item.id}"

    [item.id,
     "<a href=\"#{hn_url}\">#{item.title}</a>",
     "Score: #{item.score}"
    ].join(" | ")
  end

  # Build the body of an email for the items and send it.
  def self.email_items!(db, items)
    lines = items.map { |item| item_to_mail_body_line(item) }
    body = lines.join("\n<br>\n")
    send_email!(body)
  end

  # Send an email with the given body.
  def self.send_email!(b)
    mail = Mail.new do
      from SECRETS[:EMAIL_ADDRESS]
      to SECRETS[:EMAIL_ADDRESS]
      subject "#{Time.now}: Hacker News Update"

      html_part do
        content_type 'text/html; charset=UTF-8'
        body b
      end
    end

    mail.deliver!
  end
end
