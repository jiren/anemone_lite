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

        options = DB_ENV[:mongo]
        options = options.inject({}){|i, h| i[h[0].to_sym] = h[1]; i}

        unless options[:database]
          raise Exception.new('Mongolite Connection: Required database name.
                            i.e MongoLite::Db.connect({"database" => "test"})')
        end

        uri = "mongodb://"
        uri << "#{options[:username]}:#{options[:password]}" if(options[:username] || options[:password])
        uri << "#{options[:host] || 'localhost'}:#{options[:port] || 27017}"
        uri << "/#{options[:database]}"

        other_opts = options.reject{|k, _| [:username, :password, :host, :port, :database].include?(k)}

        @connection = Mongo::Connection.from_uri(uri, other_opts)[options[:database]]
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
