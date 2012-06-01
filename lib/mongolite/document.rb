module MongoLite
  module Document

    def self.included(base)
      base.extend MongoLite::Document::ClassMethods
      base.send(:include, MongoLite::Document::InstanceMethods)
      base.instance_variable_set('@_fields', {})
      base.send :field, :_id, :Id
    end

    def initialize(attrs = {})
      attrs['_id'] = BSON::ObjectId.new
      @attributes = {}

      self.class._fields.each do |name, opt|
        val = attrs[name] || attrs[name.to_sym] 
        @attributes[name] = Db.conveter(opt[:type], (val.nil? ? opt[:default] : val ))
      end

      yield self if block_given?
    end

    module ClassMethods
      extend Forwardable

      def_delegators :collection, :create_index, :update, :remove

      def _fields
        @_fields
      end

      def collection(name = nil)
        @_collection ||= MongoLite::Db.connect[name || self.name.split('::').last.downcase]
      end

      def field(name, type = :String, opts = {} )
        name = name.to_s
         
        if type.kind_of?(Hash)
          opts, type = type, :String
        end

        opts[:type] = type.to_sym
        @_fields[name] = opts

        field_method_reader = if type == :Binary
                                "@attributes['#{name}'].to_s"
                              else
                                "@attributes['#{name}']"
                              end

        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}
            #{field_method_reader}
          end
        METHOD

        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{name}=(val)
            @attributes['#{name}'] = Db.conveter(self.class._fields['#{name}'][:type], val)
          end
        METHOD
      end

      def create(attrs = {})
        self.new(attrs).save
      end

      def find(selector = {}, opts = {})
        selector = {:_id => Db.conveter(:Id, selector)} unless selector.kind_of?(Hash)

        self.collection.find(selector, opts).collect do |attrs|
          self.new(attrs)
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
        attrs ? self.new(attrs) : nil
      end

    end

    module InstanceMethods

      def attributes
        @attributes
      end

      def attributes=(attrs = {})
        attrs.each do |field_name, val|
          field_name = field_name.to_s
          @attributes[field_name] = Db.conveter(self.class._fields[field_name][:type], val) 
        end
      end

      def save(opts = {})
        self.class.collection.save(@attributes, opts)
        self
      end

      def update(attrs = {}, opts = {})
        self.attributes = attrs
        self.save
      end

      def destroy(opts = {})
        self.class.collection.remove({:_id => _id}, opts)
      end

    end

  end
end
