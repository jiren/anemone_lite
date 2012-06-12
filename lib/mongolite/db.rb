#Connection String Format:
#http://www.mongodb.org/display/DOCS/Connections
#i.e "mongodb://localhost:27017/test"
module MongoLite
  class Db

    BOOLEAN_MAP = {
      true => true,
      "true" => true,
      1 => true,
      "1" => true,
      1.0 => true,
      false => false,
      "false" => false,
      "0" => false,
      0 => false,
      0.0 => false
    }

    class << self

      def connect
        return @connection if @connection

        options = {}

        db_name = if ENV.has_key?('MONGODB_URI') 
                    options[:host] = "localhost"
                    options[:port] = 27017
                    ENV['MONGODB_URI'].split('/').last
                  else
                    'test'
                  end

        if ENV.has_key?('MONGODB_POOL_SIZE')
          options[:pool_size] = ENV['MONGODB_POOL_SIZE'].to_i 
        end

        @connection = Mongo::Connection.new(options.delete(:host), options.delete(:port), options)[db_name]
      end

      def close_connection
        @connection.connection.close
        @connection = nil
      end

      def conveter(type, val)
        return val if val.nil?

        case type
        when :String
          val.to_s
        when :Integer
          val.to_i
        when :Float
          val.to_f
        when :Boolean
          BOOLEAN_MAP[val]
        when :Time
          val.kind_of?(String) ? Time.new(val) : val
        when :Id
          val.kind_of?(BSON::ObjectId) ? val : BSON::ObjectId(val)
        when :Binary
          BSON::Binary.new(val)
        when :Array, :Hash
          val
        else
          val.to_s
        end
      end

    end

  end
end
