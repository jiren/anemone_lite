$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'mongolite'))

require 'mongo'
require 'ostruct'
require 'forwardable'
require 'document'
require 'db'

DB_ENV = {:mongo => {:database => 'test'} }

class Test
  include MongoLite::Document

  field :name
  field :age, :Integer, {:default => 10} 
  field :desc, :Binary
  field :url

end


Test.remove

=begin
t = Test.new({:name => 'jiren', :desc => 'aadadadaddada' })
t.desc = "aaaaaa"
t.data = "data-data"
t.save
=end
