module Anemone
  module Admin
    class Crawler
      include MongoLite::Document

      #Sates
      RUNNING, STOPED = 0, 1

      set_collection({:name => :crawlers, :database => :process_admin})

      field :process_id, :Integer, :default => $$
      field :host_name, :default => Socket.gethostname
      field :ip
      field :state, :Integer
      field :start_at
      field :stop_at
      field :page_count, :Integer, :default => 0
      field :error

      class << self

        #Add crawler record with start time, ip, hostname and process id
        def register
          return @crawler if @crawler

          ip = self.get_ip rescue 'Unknown'
          @crawler = self.create({:state => RUNNING, :start_at => Time.now, :ip => ip})
        end

        #Update current crawler record with stop time and error if present
        def unregister(page_count = 0, error = nil)
          return nil unless @crawler

          @crawler.update({:state => STOPED, 
                           :stop_at => Time.now, 
                           :page_count => page_count, 
                           :error => error})
          clear
        end

        def clear
          @crawler = nil
        end

        #Find local machine ip
        def get_ip
          # turn off reverse DNS resolution temporarily
          orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  

          UDPSocket.open do |s|
            s.connect '64.233.187.99', 1
            s.addr.last
          end
        ensure
          Socket.do_not_reverse_lookup = orig
        end

      end

    end
  end
end
