require 'json'
require 'mail'

module HackerNewsReader; end

# Methods that email me the hacker news update on a daily basis.
module HackerNewsReader::Emailer
  SECRETS = JSON.parse(
    File.read("/Users/ruggeri/.secrets.json"), symbolize_names: true
  )

  Mail.defaults do
    delivery_method :smtp, {
                      address: "email-smtp.us-west-2.amazonaws.com",
                      port: 587,
                      user_name: SECRETS[:SES_USER_NAME],
                      password: SECRETS[:SES_PASSWORD],
                      authentication: :login,
                      enable_starttls_auto: true
                    }
  end

  # Converts a story to a line with a link.
  def self.item_to_mail_body_line(item)
    hn_url = "https://news.ycombinator.com/item?id=#{item.id}"

    [item.id,
     "<a href=\"#{hn_url}\">#{item.title}</a>",
     "Score: #{item.score}"
    ].join(" | ")
  end

  # Build the body of that email. Send it. Update each item as emailed.
  def self.email_items(db, items)
    lines = items.map { |item| item_to_mail_body_line(item) }
    body = lines.join("\n<br>\n")
    send_email(body)
  end

  # Send an email with the given body.
  def self.send_email(b)
    mail = Mail.new do
      from "ruggeri@self-loop.com"
      to "ruggeri@self-loop.com"
      subject "#{Time.now}: Hacker News Update"

      html_part do
        content_type 'text/html; charset=UTF-8'
        body b
      end
    end

    mail.deliver!
  end
end
