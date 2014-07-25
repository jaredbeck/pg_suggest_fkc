#!/usr/bin/env ruby -w

require 'pp'
require 'rubygems'
require 'bundler/setup'
require 'active_support/all'
require 'pg'

class Fkc
  class DbConn

    attr_reader :db_name

    def initialize(db_name)
      @db_name = db_name
    end

    def pg_conn
      @_pg_conn ||= PG::Connection.open(dbname: db_name)
    end
  end

  class AllTablesQuery
    QRY_FILE = 'all_tables.sql'

    attr_reader :pg_conn, :namespace

    def initialize(pg_conn, namespace)
      @pg_conn = pg_conn
      @namespace = namespace.to_i
    end

    def qry_str
      File.read(QRY_FILE)
    end

    def execute
      pg_conn.exec_params(qry_str, [namespace])
    end
  end

  class UnconstrainedColumnsQuery
    QRY_FILE = 'unconstrained_foreign_keys.sql'

    attr_reader :pg_conn, :namespace

    def initialize(pg_conn, namespace)
      @pg_conn = pg_conn
      @namespace = namespace.to_i
    end

    def qry_str
      File.read(QRY_FILE)
    end

    def execute
      pg_conn.exec_params(qry_str, [namespace])
    end
  end

  class Suggestor

    attr_reader :tables, :unconstrained_fk

    def initialize(pg_conn, namespace)
      @tables = AllTablesQuery.new(pg_conn, namespace).execute
        .map { |row| row['relname'] }
      @unconstrained_fk = UnconstrainedColumnsQuery.new(pg_conn, namespace).execute
    end

    def suggestions
      unconstrained_fk.each do |r|
        plural_noun = attname_plural_noun(r['attname'])
        if tables.include?(plural_noun)
          puts Suggestion.new(r['attname'], r['relname'], plural_noun).to_sql
        end
      end
    end

    private

    def attname_plural_noun(attname)
      attname.gsub(/_id\Z/, '').pluralize
    end

  end

  class Suggestion

    FK_DELIM = '_'
    FK_PFX = 'fk'.freeze

    # Identifiers, e.g. constraint names, are truncated by postgres to NAMEDATALEN - 1 bytes.
    # http://www.postgresql.org/docs/9.3/static/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS
    NAMEDATALEN = 64.freeze

    attr_reader :foreign_key, :foreign_table, :primary_table, :primary_key

    def initialize(foreign_key, foreign_table, primary_table)
      @foreign_key = foreign_key
      @foreign_table = foreign_table
      @primary_table = primary_table
      @primary_key = 'id' # yay rails conventions :)
    end

    def to_sql
      <<-SQL
alter table "#{foreign_table}"
add constraint #{constraint_name}
foreign key ("#{foreign_key}")
references "#{primary_table}" ("#{primary_key}")
on update cascade
on delete cascade
;
      SQL
    end

    private

    def candidate_constraint_names
      @_candidate_constraint_names ||= [
        preferred_constraint_name,
        [FK_PFX, foreign_table, primary_table],
        [FK_PFX, foreign_table, foreign_key],
        terrible_constraint_name
      ].map { |ary| ary.join(FK_DELIM) }
    end

    def constraint_name
      candidate_constraint_names.find { |n| short_enough?(n) }
    end

    def preferred_constraint_name
      [FK_PFX, foreign_table, primary_table, foreign_key]
    end

    def short_enough?(n)
      n.length <= NAMEDATALEN - 1
    end

    def terrible_constraint_name
      [FK_PFX, Digest::MD5.hexdigest(preferred_constraint_name.join)]
    end
  end

  attr_reader :db_name, :namespace

  def initialize(args)
    @db_name = args[0]
    @namespace = args[1].to_i
    validate_arguments
  end

  def main
    pg_conn = DbConn.new(db_name).pg_conn
    Suggestor.new(pg_conn, namespace).suggestions
  end

  private

  def print_usage(io)
    io.puts <<-EOS
Usage: ./fkc.rb db_name namespace
db_name: name of postgres database on localhost
namespace: integer, a pg_namespace.oid
    EOS
  end

  def validate_arguments
    if db_name.blank? || namespace.nil? || namespace <= 0
      print_usage($stderr)
      exit(1)
    end
  end
end

Fkc.new(ARGV).main
