#!/usr/bin/env ruby

require 'io/console'
require_relative '../lib/database_api.rb'

module HackerNewsReader; end

class HackerNewsReader::Reviewer
  attr_reader :current_item_index, :db, :items, :num_reviewed_items, :num_remaining_items

  def initialize(db, items)
    self.current_item_index = 0
    self.db = db
    self.items = items
    self.num_reviewed_items = 0
    self.num_remaining_items = items.length
  end

  def current_item
    items[current_item_index]
  end

  def advance!
    self.num_reviewed_items += 1
    self.num_remaining_items -= 1
    self.current_item_index += 1
  end

  def retreat!
    self.num_reviewed_items -= 1
    self.num_remaining_items += 1
    self.current_item_index -= 1
  end

  # Marks an item as interesting or ignored.
  def mark_item!(marking)
    HackerNewsReader::DatabaseAPI::update_marking(
      db, current_item.id, marking
    )
    advance!
  end

  # In case you make a mistake you can undo!
  def undo_previous_marking!(marking)
    # Can't undo if we haven't done anything!
    return if current_item_index == 0

    retreat!
    HackerNewsReader::DatabaseAPI::update_marking(
      db, current_item.id, marking
    )
  end

  # Reads the command from the user.
  def read_command!
    # Puts the terminal temporarily in *noncanonical mode*. That's the
    # mode where you don't wait for a newline.
    #
    # What an unintuitive name. :-\
    STDIN.raw do |stdin|
      return stdin.getc
    end
  end

  def clear_prev_line!
    # \r means "carriage return." Moves the cursor back to the start of
    # the line.
    #
    # \033[1A tells the terminal to move up one line. \033 means "ESC".
    # [1A is the "control sequence" which means move up one line.
    #
    # \033[2K is the control sequence that clears the entire line.
    print "\r\033[1A\033[2K"
  end

  def clear_output!(output)
    # Fanciness to see how many lines of text were printed.
    number_of_terminal_columns = Float(`tput cols`)
    num_output_lines = (output.length / number_of_terminal_columns).ceil
    # Include line about number of remaining items.
    num_output_lines += 1
    # Clear all those lines.
    (num_output_lines).times { clear_prev_line! }
  end

  def review_next_item!(&prc)
    num_items_to_email = HackerNewsReader::DatabaseAPI::get_unemailed_items(
      db
    ).length

    puts [
      "#{num_remaining_items} remaining",
      "#{num_reviewed_items} reviewed",
      "#{num_items_to_email} to email"
    ].join(" | ")

    output = [:id, :title, :score].map do |attr_name|
      current_item.send(attr_name)
    end.join " | "
    puts output

    # Read a command and ask the caller what to do with this.
    prc.call read_command!

    clear_output!(output)
  end

  # Review and mark items.
  def review_items!(&prc)
    review_next_item!(&prc) while num_remaining_items > 0
  end

  private
  attr_writer :current_item_index, :db, :items, :num_reviewed_items, :num_remaining_items
end
