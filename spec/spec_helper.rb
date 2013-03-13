require File.expand_path("../../lib/logviz", __FILE__)
require 'data_mapper'
Dir[File.expand_path("models/*.rb")].each { |f| require f }
require 'rspec/autorun'

def init_db
  DataMapper.setup :default, 'sqlite::memory'
  DataMapper.finalize
  DataMapper.auto_migrate!
end