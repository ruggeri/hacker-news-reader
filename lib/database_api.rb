require_relative './item.rb'

module HackerNewsReader; end

# Methods that interact with the database.
module HackerNewsReader::DatabaseAPI
  # Get the information about a story currently stored in the db.
  def self.get_item_by_id(db, item_id)
    result = db.exec_params("SELECT * FROM items WHERE id = $1", [item_id])
    rows = result.values

    return nil if rows.empty?
    raise "id uniqueness constraint violation?!" if rows.length > 1

    HackerNewsReader::Item.from_row(rows[0], result.fields)
  end

  # Insert a story into the db. Assumes this story has never been pulled
  # before.
  def self.insert_item(db, item, pulled_at)
    item.pulled_at = pulled_at
    item.did_email = false
    item.marking = "UNMARKED"

    params = item.to_sql_params(
      [:id, :score, :title, :url, :author, :created_at, :pulled_at, :did_email, :marking]
    )

    db.exec <<-SQL, params
      INSERT INTO
        items (
          id,
          score,
          title,
          url,
          author,
          created_at,
          pulled_at,
          did_email,
          marking
        )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ;
    SQL
  end

  # Update the properties of a story previously stored in the db with
  # new data fetched from the web API.
  def self.update_item_from_web(db, item, pulled_at)
    item.pulled_at = pulled_at
    # Don't need to update emailed or marking fields.

    params = item.to_sql_params([:id, :score, :title, :url, :author, :created_at, :pulled_at])

    result = db.exec <<-SQL, params
      UPDATE
        items
      SET
        score = $2,
        title = $3,
        url = $4,
        author = $5,
        created_at = $6,
        pulled_at = $7
      WHERE
        id = $1
      ;
    SQL

    raise "No one to update?" unless result.cmd_tuples > 0
    raise "id uniqueness constraint violation??" if result.cmd_tuples > 1

    nil
  end

  # After emailing a story, remembers that you did.
  def self.update_as_emailed(db, id)
    result = db.exec <<-SQL, [id]
      UPDATE
        items
      SET
        did_email = TRUE
      WHERE
        id = $1
      ;
    SQL

    raise "No one to update?" unless result.cmd_tuples > 0
    raise "id uniqueness constraint violation??" if result.cmd_tuples > 1

    nil
  end

  # Update the marking of IGNORED/INTERESTING. Called from the review
  # command logic.
  def self.update_marking(db, id, marking)
    result = db.exec <<-SQL, [id, marking]
      UPDATE
        items
      SET
        marking = $2
      WHERE
        id = $1
      ;
    SQL

    raise "No one to update?" unless result.cmd_tuples > 0
    raise "id uniqueness constraint violation??" if result.cmd_tuples > 1

    nil
  end

  # Get items that have not been previously emailed.
  def self.get_unemailed_items(db)
    result = db.exec <<-SQL
      SELECT
        *
      FROM
        items
      WHERE
        did_email = FALSE AND marking = 'INTERESTING'
      ORDER BY
        score DESC
      ;
    SQL
    rows = result.values
    fields = result.fields

    items = rows.map { |r| HackerNewsReader::Item.from_row(r, fields) }
    items
  end

  # Get Items that have never been marked. These need to be reviewed.
  def self.get_unmarked_items(db)
    result = db.exec <<-SQL
      SELECT
        *
      FROM
        items
      WHERE
        marking = 'UNMARKED'
      ORDER BY
        score DESC
      ;
    SQL
    rows = result.values
    fields = result.fields

    items = rows.map { |r| HackerNewsReader::Item.from_row(r, fields) }
    items
  end
end
