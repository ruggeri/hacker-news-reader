require 'pg'

module HackerNewsReader; end

# Methods that build the underlying db connection.
module HackerNewsReader::DatabaseConnection
  DB_NAME = "hacker_news"

  # Gets a db connection.
  def self.get_db_connection
    return @db if @db

    @db = PG.connect(dbname: DB_NAME)

    # In case this is our first time, setup the tables.
    maybe_add_marked_enum(@db)
    maybe_add_items_table(@db)

    @db
  end

  def self.maybe_add_marked_enum(db)
    db.exec <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marking') THEN
          CREATE TYPE marking AS ENUM (
            'UNMARKED',
            'IGNORED',
            'INTERESTING'
          );
        END IF;
      END$$;
    SQL
  end

  def self.maybe_add_items_table(db)
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER NOT NULL UNIQUE,
        score INTEGER NOT NULL,
        title VARCHAR(1024) NOT NULL,
        url VARCHAR(1024),
        author VARCHAR(1024) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE NOT NULL,
        pulled_at TIMESTAMP WITH TIME ZONE NOT NULL,
        did_email BOOLEAN NOT NULL,
        marking marking NOT NULL
      );
    SQL
  end
end
