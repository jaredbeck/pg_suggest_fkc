#!/usr/bin/env ruby -w

require 'rubygems'
require 'bundler/setup'
require 'pg'

class Fkc
  class Query
    QRY_FILE = 'unconstrained_foreign_keys.sql'

    def new
    end

    def qry
      File.read(QRY_FILE)
    end
  end

  def new(args)
  end

  def main
  end
end

Fkc.new(ARGV).main
