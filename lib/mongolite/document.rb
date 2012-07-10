module MongoLite
  module Document

    def self.included(base)
      base.extend MongoLite::Document::ClassMethods
      base.send(:include, MongoLite::Document::InstanceMethods)

      #Set default db collection
      base.set_collection
      base.instance_variable_set('@_fields', {})
      base.send :field, :_id, :Id
    end

    def initialize(attrs = {}, from_db = false)
      attrs['_id'] ||= BSON::ObjectId.new
      @attributes = {}

      self.class._fields.each do |name, opt|
        val = attrs[name] || attrs[name.to_s] || opt[:default]
        @attributes[name] = Db.conveter(opt[:type], val)
      end

      yield self if block_given?
    end

    module ClassMethods
      #extend Forwardable
      #def_delegators :collection, :update, :create_index, :remove
      #alias :index :create_index

      def set_collection(opts = {:name => nil, :database => nil})
        opts[:name] ||= self.name.split('::').last.downcase

        @_collection = if opts[:database].nil?
                         MongoLite::Db.connection[opts[:name]]
                       else
                         MongoLite::Db.secondary_connections(opts[:database])[opts[:name]]
                       end
      end

      def collection
        @_collection # ||= MongoLite::Db.connect[name || self.name.split('::').last.downcase]
      end

      def _fields
        @_fields
      end

      def field(name, type = :String, opts = {} )
        name = name.to_sym

        if type.kind_of?(Hash)
          opts, type = type, :String
        end

        opts[:type] = type.to_sym
        @_fields[name] = opts

        field_method_reader = if type == :Binary
                                "@attributes[:#{name}].to_s"
                              else
                                "@attributes[:#{name}]"
                              end

        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            #{field_method_reader}
          end
        METHOD

        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}=(val)
            @attributes[:#{name}] = Db.conveter(self.class._fields[:#{name}][:type], val)
          end
        METHOD
      end

      def create(attrs = {})
        self.new(attrs).save
      end

      def find(selector = {}, opts = {})
        selector = {:_id => Db.conveter(:Id, selector)} unless selector.kind_of?(Hash)

        self.collection.find(selector, opts).collect do |attrs|
          self.new(attrs, true)
        end
      end

      def all
        self.find
      end

      def first(selector = {})
        self.find(selector, {:limit => -1}).first
      end

      def last(selector = {})
        self.find(selector, {:sort => [ :_id, :desc ], :limit => 1}).first
      end

      def count(selector = {}, opts = {})
        self.collection.count(:query => selector)
      end
       
      def exists?(selector)
        count(selector, :limit => 1) == 1
      end

      def find_and_modify(selector = {}, document = {})
        attrs = self.collection.find_and_modify({
          :query => selector,
          :update => {'$set' => document },
          :new => true})

        attrs ? self.new(attrs, true) : nil
      end

      %w(update remove create_index).each do |m|
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{m}(*args)
            @_collection.#{m}(*args)
          end
        METHOD
      end

      alias :index :create_index 

    end

    module InstanceMethods

      def attributes
        @attributes
      end

      def attributes=(attrs = {})
        attrs.each do |field_name, val|
          field_name = field_name.to_sym
          @attributes[field_name] = Db.conveter(self.class._fields[field_name][:type], val) 
        end
      end

      def save(opts = {})
        self.class.collection.save(@attributes, opts)
        self
      end

      def update(attrs = {}, opts = {})
        self.attributes = attrs
        self.class.collection.update({:_id => self._id}, self.attributes)
      end

      def destroy(opts = {})
        self.class.collection.remove({:_id => _id}, opts)
      end

    end

  end
end
