module Anemone
  class Page
    include MongoLite::Document
    include Anemone::Queue

    collection :pages

    # The URL of the page
    field :url
    # The raw HTTP response body of the page
    field :body, :Binary
    # Headers of the HTTP response
    field :headers, :Binary
    # URL of the page this one redirected to, if any
    field :redirect_to
    # Exception object, if one was raised during HTTP#fetch_page
    field :error

    # OpenStruct for user-stored data
    #field :data, :OpenStruct, :default => OpenStruct.new
    # Integer response code of the page
    field :code, :Integer
    # Boolean indicating whether or not this page has been visited in PageStore#shortest_paths!
    field :visited, :Boolean
    # Depth of this page from the root of the crawl. This is not necessarily the
    # shortest path; use PageStore#shortest_paths! to find that value.
    field :depth, :Integer, :default => 0
    # URL of the page that brought us to this page
    field :referer
    # Response time of the request for this page in milliseconds
    field :response_time, :Integer

    field :connected_links, :Array, :default => []
    field :fetched, :Boolean, :default => false

    field :parse_status, :Integer, :default => 0

    #
    # Create a new page
    #
    def initialize(attrs = {})
      attrs[:headers] ||= {}
      attrs[:headers]['content-type'] ||= ['']
      attrs[:headers] = Marshal.dump(attrs[:headers])
      attrs[:fetched] = !attrs[:code].nil?
      attrs[:state] ||= NEW
      attrs[:fetched_at] = Time.now

      super attrs

      #After body initialize set redirect url
      redirect_to = to_absolute(attrs[:redirect_to])
    end

    def headers
      Marshal.load(attributes['headers'].to_s)
    end

    #
    # Array of distinct A tag HREFs from the page
    #
    def links
      return @page_links if @page_links

      @page_links = []
      return @page_links if !doc

      doc.search("//a[@href]").each do |a|
        u = a['href']
        next if u.nil? or u.empty?
        abs = to_absolute(u) rescue next
        @page_links << abs if in_domain?(abs)
      end
      @page_links.uniq!

      self.connected_links = @page_links.map(&:to_s)
    end

    #
    # Nokogiri document for the HTML body
    #
    def doc
      return @doc if @doc
      @doc = Nokogiri::HTML(body) if body && html? #rescue nil
    end

    #
    # Delete the Nokogiri document and response body to conserve memory
    #
    def discard_doc!
      links # force parsing of page links before we trash the document
      @doc = body = nil
      self.save
    end

    #
    # Was the page successfully fetched?
    # +true+ if the page was fetched with no error, +false+ otherwise.
    #
    def fetched?
      fetched
    end
    
    #alias :'fetched?', :fetched

    #
    # Array of cookies received with this page as WEBrick::Cookie objects.
    #
    def cookies
      WEBrick::Cookie.parse_set_cookies(headers['Set-Cookie']) rescue []
    end

    #
    # The content-type returned by the HTTP request for this page
    #
    def content_type
      headers['content-type'].first
    end

    #
    # Returns +true+ if the page is a HTML document, returns +false+
    # otherwise.
    #
    def html?
      !!(content_type =~ %r{^(text/html|application/xhtml+xml)\b})
    end

    #
    # Returns +true+ if the page is a HTTP redirect, returns +false+
    # otherwise.
    #
    def redirect?
      (300..307).include?(code)
    end

    #
    # Returns +true+ if the page was not found (returned 404 code),
    # returns +false+ otherwise.
    #
    def not_found?
      404 == code
    end

    #
    # Base URI from the HTML doc head element
    # http://www.w3.org/TR/html4/struct/links.html#edef-BASE
    #
    def base
      @base = if doc
        href = doc.search('//head/base/@href')
        URI(href.to_s) unless href.nil? rescue nil
      end unless @base
      
      return nil if @base && @base.to_s().empty?
      @base
    end


    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    def to_absolute(link)
      return nil if link.nil?

      # remove anchor
      link = URI.encode(URI.decode(link.to_s.gsub(/#[a-zA-Z0-9_-]*$/,'')))

      relative = URI(link)
      absolute = base ? base.merge(relative) : URI(url).merge(relative)

      absolute.path = '/' if absolute.path.empty?

      return absolute
    end

    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?(uri)
      uri.host == URI(url).host
    end

    def self.[](page_url)
      self.first(:url => page_url.to_s)
    end

  end
end
