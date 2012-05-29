module Anemone
  class PageStore

    # Does this PageStore contain the specified URL?
    # HTTP and HTTPS versions of a URL are considered to be the same page.
    def has_page?(url)
      page_url = URI(url)
      schemes = %w(http https)

      if schemes.include? page_url.scheme
        u = url.dup
        return schemes.any? { |s| u.scheme = s; Page.exists?(:url => u.to_s) }
      end

      Page.exists?(:url => page_url.to_s)
    end

    #
    # Use a breadth-first search to calculate the single-source
    # shortest paths from *root* to all pages in the PageStore
    #
    def shortest_paths!(root)
      root = URI(root) if root.is_a?(String)
      raise "Root node not found" if !has_key?(root)

      q = Queue.new

      q.enq root
      root_page = Page[root]
      root_page.depth = 0
      root_page.visited = true
      root_page.save

      while !q.empty?
        page = Page[q.deq]
        page.links.each do |u|
          begin
            link = Page[u]
            next if link.nil? || !link.fetched? || link.visited

            q << u unless link.redirect?
            link.visited = true
            link.depth = page.depth + 1
            link.save

            if link.redirect?
              u = link.redirect_to
              redo
            end
          end
        end
      end

      self
    end

    #
    # If given a single URL (as a String or URI), returns an Array of Pages which link to that URL
    # If given an Array of URLs, returns a Hash (URI => [Page, Page...]) of Pages linking to those URLs
    #
    def pages_linking_to(urls)
      unless urls.is_a?(Array)
        urls = [urls]
        single = true
      end

      urls.map! do |url|
        unless url.is_a?(URI)
          URI(url) rescue nil
        else
          url
        end
      end
      urls.compact

      links = {}
      urls.each { |url| links[url] = [] }
      values.each do |page|
        urls.each { |url| links[url] << page if page.links.include?(url) }
      end

      if single and !links.empty?
        return links[urls.first]
      else
        return links
      end
    end

    #
    # If given a single URL (as a String or URI), returns an Array of URLs which link to that URL
    # If given an Array of URLs, returns a Hash (URI => [URI, URI...]) of URLs linking to those URLs
    #
    def urls_linking_to(urls)
      unless urls.is_a?(Array)
        urls = [urls] unless urls.is_a?(Array)
        single = true
      end

      links = pages_linking_to(urls)
      links.each { |url, pages| links[url] = pages.map{|p| p.url} }

      if single and !links.empty?
        return links[urls.first]
      else
        return links
      end
    end

  end
end
