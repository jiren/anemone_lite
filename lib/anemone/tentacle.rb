require 'anemone/http'

module Anemone
  class Tentacle

    #
    # Create a new Tentacle
    #
    def initialize(opts = {})
      @http = Anemone::HTTP.new(opts)
      @opts = opts
    end

    #
    # Gets links from @link_queue, and returns the fetched
    # Page objects into @page_queue
    #
    def run
      loop do
        if link = Link.deq

          @http.fetch_pages(link.url, link.referer, link.depth)

          delay
        end
      end
    end

    private

    def delay
      sleep @opts[:delay] if @opts[:delay] > 0
    end

  end
end