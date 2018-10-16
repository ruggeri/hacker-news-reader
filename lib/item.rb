require 'time'
require_relative './item_conversions.rb'

module HackerNewsReader; end

# The class that represents a Hacker News item.
class HackerNewsReader::Item
  MARKING_VALUES = ["UNMARKED", "IGNORED", "INTERESTING", "OPENED"]

  # These are class/instance methods that convert to/from web JSON, DB,
  # and Item formats.
  extend HackerNewsReader::ClassItemConversions
  include HackerNewsReader::InstanceItemConversions

  # These are the attributes that come from the Hacker News API. I
  # specify their types too.
  JSON_ATTRS = {
    id: Integer,
    score: Integer,
    title: String,
    url: String,
    author: String,
    created_at: Time,
  }

  # These are the attributes we add as part of the application.
  APP_ATTRS = [
    :did_email,
    :marking,
    :pulled_at,
  ]

  # Add readers for JSON attributes. We won't be able to modify them.
  # We'll add custom readers/writers for application attributes.
  attr_reader *JSON_ATTRS.keys

  def initialize(attrs)
    # Copy over all the JSON attributes, checking that they are the
    # right type of value.
    JSON_ATTRS.each do |attr_name, expected_type|
      attr_value = attrs[attr_name]
      value_type = attr_value.class

      # All attributes are supposed to be present, except maybe the url
      # because some items are Ask HNs.
      unless attr_name == :url
        raise "Required key: #{attr_name}. Got nil." if attr_value.nil?
      end

      if attr_value != nil && expected_type != value_type
        raise "Expected type #{expected_type} for #{attr_name}. Got #{attr_value.inspect} instead."
      end

      instance_variable_set("@#{attr_name}", attr_value)
    end

    APP_ATTRS.each do |attr_name|
      attr_value = attrs[attr_name]

      # APP_ATTRS are not required values. We skip any not present.
      next if attr_value.nil?

      self.send("#{attr_name}=", attr_value)
    end
  end

  # Getters/setters for did_email.
  def did_email=(attr_value)
    unless [true, false].include?(attr_value)
      raise "Expected true/false value for did_email. Got: #{attr_value.inspect} instead."
    end

    @did_email = attr_value
  end

  def did_email
    # If did_email was never set, don't let them try to use it.
    raise "did_email attribute was never set!" if @did_email.nil?
    @did_email
  end

  # Alias reader method.
  def emailed?
    did_email
  end

  # Getters/setters for marking.
  def marking=(attr_value)
    unless MARKING_VALUES.include?(attr_value)
      raise "Expected marking enum value. Got: #{attr_value.inspect} instead."
    end

    @marking = attr_value
  end

  def marking
    # If marking was never set, don't let them try to use it.
    raise "Marking attribute was never set!" if @marking.nil?
    @marking
  end

  # Helpers for marking attribute.
  def ignored?
    marking == "IGNORED"
  end

  def interesting?
    marking == "INTERESTING"
  end

  def opened?
    marking == "OPENED"
  end

  # Getters/setters for pulled_at.
  def pulled_at=(attr_value)
    unless attr_value.instance_of?(Time)
      raise "Expected type Time for #{attr_name}. Got #{attr_value.inspect} instead."
    end

    @pulled_at = attr_value
  end

  def pulled_at
    # If pulled_at was never set, don't let them try to use it.
    raise "pulled_at attribute was never set!" if @pulled_at.nil?
    @pulled_at
  end
end
