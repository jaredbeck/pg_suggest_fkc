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
        pp r.to_hash
        plural_noun = r['attname'].gsub(/_id\Z/, '').pluralize
        if tables.include?(plural_noun)
          puts "#{plural_noun} is a table!"
        end
      end
    end
  end

  class Suggestion
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
