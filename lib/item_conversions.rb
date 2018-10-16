module HackerNewsReader; end

# Class methods that convert an Item to/from other representations.
module HackerNewsReader::ClassItemConversions
  # Converts from API JSON format to our Item format.
  def from_json(json)
    self.new({
      id: Integer(json[:id]),
      score: Integer(json[:score]),
      title: json[:title],
      url: json[:url],
      author: json[:by],
      created_at: Time.at(Integer(json[:time])),
    })
  end

  # Converts from the database representation to the Item format. `row`
  # is the result row that PG::Result to us. `fields` is the list of
  # field names that PG::Result gives us.
  def from_row(row, fields)
    item_attrs = {}

    # Iterate over each field returned, and copy it to the item
    # attributes.
    fields.each_with_index do |attr_name, idx|
      # PG::Result field names are strings. Convert to symbol.
      attr_name = attr_name.to_sym
      attr_value = row[idx]

      item_attrs[attr_name] = attr_value
    end

    # Convert did_email attribute to a boolean value.
    case item_attrs[:did_email]
    when "t"
      item_attrs[:did_email] = true
    when "f"
      item_attrs[:did_email] = false
    else
      raise "Unexpected did_email value: #{item_attrs[:did_email].inspect}."
    end

    # Build item, parsing all the attributes.
    self.new({
      id: Integer(item_attrs[:id]),
      score: Integer(item_attrs[:score]),
      title: item_attrs[:title],
      url: item_attrs[:url],
      author: item_attrs[:author],
      marking: item_attrs[:marking],
      created_at: Time.parse(item_attrs[:created_at]),
      pulled_at: Time.parse(item_attrs[:pulled_at]),
      did_email: item_attrs[:did_email] == "t" ? true : false,
    })
  end
end

# Instance methods that convert an Item to/from other representations.
module HackerNewsReader::InstanceItemConversions
  # Converts an Item object back into a representation that can be
  # interpolated into a SQL query.
  def to_sql_params(attr_names)
    sql_params = []

    attr_names.each do |attr_name|
      if [:id, :score, :title, :url, :author, :did_email, :marking].include?(attr_name)
        sql_params << self.send(attr_name)
      elsif [:created_at, :pulled_at].include?(attr_name)
        # Must convert to ISO format.
        sql_params << self.send(attr_name).to_s
      else
        raise "Unknown key: #{attr_name}!"
      end
    end

    sql_params
  end
end
