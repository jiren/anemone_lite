#Connection String Format:
#http://www.mongodb.org/display/DOCS/Connections
#i.e "mongodb://localhost:27017/test"
#    "mongodb://localhost:27017/test,localhost:27017/admin"
module MongoLite
  class Db

    BOOLEAN_MAP = {
      true  => true,
      'true' => true,
      1 => true,
      '1' => true,
      1.0 => true,
      false => false,
      'false' => false,
      '0' => false,
      0 => false,
      0.0 => false
    }

    class << self

      def config
        return if config? 

        config_file, env = if ENV['CRAWLER']
                             params = Hash[ENV['CRAWLER'].split(',').collect { |i| i.split(':') }]
                             [ params['db_config'], params['env'] ]
                           else
                             [nil, nil]
                           end

        config_file ||= 'config/mongo.yml'
        env ||= 'development'

        config_data = YAML.load_file(config_file)[env]
        @connection = self.build_connection(config_data)

        return unless config_data['databases']

        @secondary_connections = {}
        config_data['databases'].each do |db_name, opts|
          @secondary_connections[db_name.to_sym] = self.build_connection(opts)
        end

        @config = true
      end

      def config?
        @config 
      end
      
      def secondary_connections(db_name)
        @secondary_connections[db_name]
      end

      def connection
        self.config unless @connection
        @connection
      end

      def build_connection(config_data = {})
         mongo_uri = Mongo::URIParser.new(config_data['uri'])

         db_name = config_data['uri'].split('/').last

         extra_opts = {}
         config_data.reject{|k,v| ['databases', 'uri'].include?(k)}.each do |k, v|
           extra_opts[k.to_sym] = v
         end

         extra_opts = extra_opts
         extra_opts.merge!(mongo_uri.connection_options)

         conn = Mongo::Connection.new(mongo_uri.nodes[0][0], mongo_uri.nodes[0][1], extra_opts).tap do |c|
           c.apply_saved_authentication
         end

         conn[db_name]
      end

      def close_connection
        @connection.connection.close
        @connection = nil

        @secondary_connections.each do |sc|
          sc.connection.close
        end
        @secondary_connections = nil
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
          val.kind_of?(BSON::Binary) ? val : BSON::Binary.new(val)
        when :Array, :Hash
          val
        else
          val.to_s
        end
      end

    end

  end
end
