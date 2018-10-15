require 'time'

module HackerNewsReader; end

class HackerNewsReader::Item
  JSON_ATTRS = [:id, :score, :title, :url, :author, :created_at]
  APP_ATTRS = [:did_email, :pulled_at, :marking]

  attr_reader *JSON_ATTRS
  attr_writer *APP_ATTRS

  def initialize(attrs)
    (JSON_ATTRS + APP_ATTRS).each do |attr|
      next if attrs[attr].nil?
      instance_variable_set("@#{attr}", attrs[attr])
    end
  end

  def did_email
    raise "Unset attribute!" if @did_email.nil?
    @did_email
  end

  def emailed?
    did_email
  end

  def marking
    raise "Unset attribute!" if @marking.nil?
    @marking
  end

  def ignored?
    marking == "IGNORED"
  end

  def interesting?
    marking == "INTERESTING"
  end

  def pulled_at
    raise "Unset attribute!" if @pulled_at.nil?
    @pulled_at
  end

  # Converts from format from website to our format.
  def self.from_json(json)
    item_attrs = {}

    item_attrs[:id] = json[:id]
    item_attrs[:score] = Integer(json[:score])
    item_attrs[:title] = json[:title]
    item_attrs[:url] = json[:url]
    item_attrs[:author] = json[:by]
    item_attrs[:created_at] = Time.at(Integer(json[:time]))

    Item.new(item_attrs)
  end

  def to_params(keys)
    params = []

    keys.each do |key|
      if [:id, :score, :title, :url, :author, :did_email, :marking].include?(key)
        params << self.send(key)
      elsif [:created_at, :pulled_at].include?(key)
        # Must convert to ISO format.
        params << self.send(key).to_s
      else
        raise "Unknown key: #{key}!"
      end
    end

    params
  end

  def self.from_row(row, fields)
    item_attrs = {}
    fields.each_with_index do |key, idx|
      key = key.to_sym
      value = row[idx]

      if [:id, :title, :url, :author, :marking].include?(key)
        item_attrs[key] = value
      elsif [:score].include?(key)
        item_attrs[key] = Integer(value)
      elsif [:created_at, :pulled_at].include?(key)
        item_attrs[key] = Time.parse(value)
      elsif [:did_email].include?(key)
        if value == "f"
          item_attrs[key] = false
        elsif value == "t"
          item_attrs[key] = true
        else
          raise "wtf"
        end
      else
        raise "Unknown key: #{key}"
      end
    end

    Item.new(item_attrs)
  end
end
