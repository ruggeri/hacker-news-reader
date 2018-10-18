require 'pg'
require_relative './config.rb'

module HackerNewsReader; end

# Methods that build the underlying db connection.
module HackerNewsReader::DatabaseConnection
  # To use these scripts, you'll have to `createdb hacker_news`. You can
  # change the name of the database in the config file if you like.
  DB_NAME = HackerNewsReader::Config::DB_NAME

  # Gets a Postgres db connection.
  def self.get_db_connection
    return @db if @db

    @db = PG.connect(dbname: DB_NAME)

    # In case this is our first time, setup the tables.
    maybe_create_db
    maybe_add_marked_enum(@db)
    maybe_add_items_table(@db)

    @db
  end

  # This means you don't even need to createdb yourself!
  def self.maybe_create_db
    # This isn't foolproof. You can trick this.
    num_dbs = Integer(`psql -l | grep #{DB_NAME} | wc -l`.chomp)
    return if num_dbs > 0

    `createdb #{DB_NAME}`
  end

  # This creates a Postgres type to mark whether we are interested in a
  # story. The possible values are 'UNMARKED', 'IGNORED', and
  # 'INTERESTING'.
  #
  # Postgres will be smart enough to use just two bits per row to store
  # this value: it won't store the whole string. Plus, Postgres will
  # tell us if we try to set the marking to 'BLAH_BLAH_BLAH' or
  # something.
  #
  # This just creates the type. We'll use it when creating the table.
  #
  # I need to use DO/END because I'll also be using an IF NOT. I'm
  # checking in case I've already defined the marking type.
  def self.maybe_add_marked_enum(db)
    db.exec <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'marking') THEN
          CREATE TYPE marking AS ENUM (
            'UNMARKED',
            'IGNORED',
            'INTERESTING',
            'OPENED',
            'SKIPPED_OPENING'
          );
        END IF;
      END$$;
    SQL
  end

  # Creates the items table if this hasn't been done yet. This will
  # store the pulled hacker news stories.
  def self.maybe_add_items_table(db)
    db.exec <<-SQL
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'items') THEN
          CREATE TABLE items (
            -- Hacker news gives us an item id.
            id INTEGER NOT NULL UNIQUE,
            -- The number of upvotes.
            score INTEGER NOT NULL,
            title VARCHAR(1024) NOT NULL,
            -- Sometimes there is no URL if this is an "Ask HN" post.
            url VARCHAR(1024),
            author VARCHAR(1024) NOT NULL,
            -- The time the story was authored at.
            created_at TIMESTAMP WITH TIME ZONE NOT NULL,
            -- When have we most recently pulled the story.
            pulled_at TIMESTAMP WITH TIME ZONE NOT NULL,
            -- Did we already email ourselves this story?
            did_email BOOLEAN NOT NULL,
            -- Is the story interesting?
            marking marking NOT NULL
          );
        END IF;
      END$$;
    SQL
  end
end
