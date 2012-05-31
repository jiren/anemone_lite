module Anemone
  module Queue

    NEW       = 0
    PROCESSED = 1
    #PROCESSED = 2

    def self.included(base)
      base.extend Anemone::Queue::ClassMethods
      base.send(:include, Anemone::Queue::InstanceMethods)

      base.send :field, :state, :Integer, :default => NEW 
      base.send :field, :fetched_at, :Time
      base.send :field, :process_id, :Integer, :default => $$
      base.send :field, :host_name, :default => Socket.gethostname
    end

    module ClassMethods
      def deq
        self.find_and_modify({:state => NEW}, {:state => PROCESSED})
      end

      def enq(attrs)
        self.create(attrs) unless self.exists?(:url => attrs[:url].to_s)
      end

      def queue_empty?
        self.count(:state => NEW) == 0
      end

    end

    module InstanceMethods

      def enq
        self.save unless self.class.exists?(:url => url)
      end

      def processed
        self.class.update({:_id => _id}, {:state => PROCESSED})
      end

      def processed?
        state == PROCESSED
      end
    end
  end
end
