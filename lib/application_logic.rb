require 'io/console'

require_relative './config.rb'
require_relative './database_api.rb'
require_relative './emailer.rb'
require_relative './web_api.rb'

# The main logic of the application.
module HackerNewsReader::ApplicationLogic
  # Decides whether we should pull new data about a previously stored
  # story. This keeps things like the link, story name, author, score up
  # to date.
  def self.should_pull?(stored_item)
    return true if stored_item.nil?
    # There is no need to update information about a story we have
    # previously emailed about.
    return false if stored_item.did_email

    time_diff = Time.now - stored_item.pulled_at
    time_diff > Config::SECONDS_BEFORE_REFRESH
  end

  # Pulls down a list of the best stories. For each best story, if not
  # yet emailed, pulls down more info. Will then update the stored info
  # in the db.
  def self.pull_best_items_and_update(db)
    WebAPI::pull_best_ids.each do |new_id|
      puts "#{new_id}: Fetching stored value" if Config::FETCH_LOGGING
      stored_item = DatabaseAPI::get_item_by_id(db, new_id)

      unless should_pull?(stored_item)
        puts "#{new_id}: Skipping" if Config::FETCH_LOGGING
        next
      end
      puts "#{new_id}: Pulling"
      pulled_item = WebAPI::pull_item(new_id)

      if stored_item.nil?
        puts "#{new_id}: Storing" if Config::FETCH_LOGGING
        DatabaseAPI::insert_item(db, pulled_item, Time.now)
      else
        puts "#{new_id}: Updating" if Config::FETCH_LOGGING
        DatabaseAPI::update_item_from_web(db, pulled_item, Time.now)
      end
    end
  end

  def self.should_email_items?(items_to_email)
    if items_to_email.empty?
      puts "No items to send!"
      return
    elsif items_to_email.length < Config::MIN_EMAIL_LENGTH
      puts "#{items_to_email.length} new items. Waiting to email."
      return
    end
  end

  # Build and send the email of stories.
  def self.email_items(db)
    items_to_email = DatabaseAPI::get_unemailed_items(db)

    return unless should_email_items?(items_to_email)
    Emailer::email_items(db, items_to_email)

    items_to_email.each { |i| DatabaseAPI::update_as_emailed(db, i.id) }

    puts "Emailed #{items_to_email.length} items!"
  end

  def self.review_items(db)
    unmarked_items = DatabaseAPI::get_unmarked_items(db)
    marked_items = 0

    idx = 0
    while idx < unmarked_items.length
      item = unmarked_items[idx]
      puts "#{unmarked_items.length - marked_items} unmarked items!"
      puts [item.id, item.title, item.score].join " | "

      command = nil
      # Puts the terminal in *noncanonical mode*. That's the mode where
      # you don't wait for enter. What a stupid name.
      STDIN.raw do |stdin|
        command = stdin.getc
      end

      case command
      when "f"
        DatabaseAPI::update_marking(db, item.id, "INTERESTING")
        marked_items += 1
        idx += 1
      when "j"
        DatabaseAPI::update_marking(db, item.id, "IGNORED")
        marked_items += 1
        idx += 1
      when "u"
        raise "hell" if idx == 0

        marked_items -= 1
        idx -= 1
        prev_item = unmarked_items[idx]
        DatabaseAPI::update_marking(db, prev_item.id, "UNMARKED")
      when "\cc"
        puts "Goodbye!"
        exit
      end

      # Go back two lines. Erase them.
      print "\r\033[1A\033[2K"
      print "\r\033[1A\033[2K"
    end
  end
end
