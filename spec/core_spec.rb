$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone
  describe Core do

    before(:each) do
      FakeWeb.clean_registry
      Link.remove
      Page.remove

      @opts = {:queue_timeout => 1}
    end

    describe "crawl" do
      it "should crawl all the html pages in a domain by following <a> href's" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '2'])
        pages << FakePage.new('1', :links => ['3'])
        pages << FakePage.new('2')
        pages << FakePage.new('3')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts)
        Page.count.should == 4
      end

      it "should not follow links that leave the original domain" do
        pages = []
        pages << FakePage.new('0', :links => ['1'], :hrefs => 'http://www.other.com/')
        pages << FakePage.new('1')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts)

        Page.count.should == 2
        Page['http://www.other.com/'].should == nil
      end

      it "should not follow redirects that leave the original domain" do
        pages = []
        pages << FakePage.new('0', :links => ['1'], :redirect => 'http://www.other.com/')
        pages << FakePage.new('1')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts)

        Page.count.should == 2
        Page['http://www.other.com/'].should == nil
      end

      it "should follow http redirects" do
        pages = []
        pages << FakePage.new('0', :links => ['1'])
        pages << FakePage.new('1', :redirect => '2')
        pages << FakePage.new('2')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts)
        Page.count.should == 3
      end

      it "should follow with HTTP basic authentication" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '2'], :auth => true)
        pages << FakePage.new('1', :links => ['3'], :auth => true)

        Link.enq(:url => pages[0].auth_url)
        Anemone.crawl(@opts)
        Page.count.should == 2
      end

      it "should accept multiple starting URLs" do
        pages = []
        pages << FakePage.new('0', :links => ['1'])
        pages << FakePage.new('1')
        pages << FakePage.new('2', :links => ['3'])
        pages << FakePage.new('3')

        Link.enq(:url => pages[0].url)
        Link.enq(:url => pages[2].url)

        Anemone.crawl(@opts)
        Page.count.should == 4
      end

      it "should include the query string when following links" do
        pages = []
        pages << FakePage.new('0', :links => ['1?foo=1'])
        pages << FakePage.new('1?foo=1')
        pages << FakePage.new('1')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts)

        Page.count.should == 2
        Page[pages[2].url].should == nil
      end

      it "should be able to skip links with query strings" do
        pages = []
        pages << FakePage.new('0', :links => ['1?foo=1', '2'])
        pages << FakePage.new('1?foo=1')
        pages << FakePage.new('2')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts) do |a|
          a.skip_query_strings = true
        end

        Page.count.should == 2
      end

      it "should be able to skip links based on a RegEx" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '2'])
        pages << FakePage.new('1')
        pages << FakePage.new('2')
        pages << FakePage.new('3')

        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts) do |a|
          a.skip_links_like /1/, /3/
        end

        Page.count.should == 2
        Page[pages[1].url] == nil
        Page[pages[3].url] == nil
      end

      it "should be able to call a block on every page" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '2'])
        pages << FakePage.new('1')
        pages << FakePage.new('2')

        count = 0
        Link.enq(:url => pages[0].url)
        Anemone.crawl(@opts) do |a|
          a.on_every_page { count += 1 }
        end

        count.should == 3
      end

      it "should not discard page bodies by default" do
        Link.enq(:url => FakePage.new('0').url)
        Anemone.crawl(@opts)
        Page.first.body.should_not be_nil
      end

      it "should optionally discard page bodies to conserve memory" do
        # core = Anemone.crawl(FakePage.new('0').url, @opts.merge({:discard_page_bodies => true}))
        # core.pages.values.first.doc.should be_nil
      end

      it "should provide a focus_crawl method to select the links on each page to follow" do
        pages = []
        pages << FakePage.new('0', :links => ['1', '2'])
        pages << FakePage.new('1')
        pages << FakePage.new('2')

        Link.enq(:url => pages[0].url)
        core = Anemone.crawl(@opts) do |a|
          a.focus_crawl {|p| p.links.reject{|l| l.to_s =~ /1/}}
        end

        Page.count.should == 2
        Page[pages[1].url].should == nil
      end

      it "should optionally delay between page requests" do
        delay = 0.25

        pages = []
        pages << FakePage.new('0', :links => '1')
        pages << FakePage.new('1')

        Link.enq(:url => pages[0].url)
        start = Time.now
        Anemone.crawl(@opts.merge({:delay => delay}))
        finish = Time.now

        (finish - start).should satisfy {|t| t > delay * 2}
      end

      it "should optionally obey the robots exclusion protocol" do
        pages = []
        pages << FakePage.new('0', :links => '1')
        pages << FakePage.new('1')
        pages << FakePage.new('robots.txt',
                              :body => "User-agent: *\nDisallow: /1",
                              :content_type => 'text/plain')

        Link.enq(:url => pages[0].url)
        core = Anemone.crawl(@opts.merge({:obey_robots_txt => true}))
        urls = Page.all.collect(&:url)

        urls.should include(pages[0].url)
        urls.should_not include(pages[1].url)
      end

      it "should be able to set cookies to send with HTTP requests" do
        cookies = {:a => '1', :b => '2'}
        page = FakePage.new('0')

        Link.enq(:url => page.url)
        core = Anemone.crawl(@opts) do |anemone|
          anemone.cookies = cookies
        end
        core.opts[:cookies].should == cookies
      end

      it "should freeze the options once the crawl begins" do
        page = FakePage.new('0')
        Link.enq(:url => page.url)

        core = Anemone.crawl(@opts) do |anemone|
          anemone.threads = 4
          anemone.on_every_page do
            lambda {anemone.threads = 2}.should raise_error
          end
        end
        core.opts[:threads].should == 4
      end

      describe "many pages" do
        before(:each) do
          @pages, size = [], 5

          size.times do |n|
            # register this page with a link to the next page
            link = (n + 1).to_s if n + 1 < size
            @pages << FakePage.new(n.to_s, :links => Array(link))
          end
        end

        it "should track the page depth and referer" do
          Link.enq(:url => @pages[0].url)
          core = Anemone.crawl(@opts)
          previous_page = nil

          @pages.each_with_index do |page, i|
            page = Page[page.url]
            page.should be
            page.depth.should == i

            if previous_page
              page.referer.should == previous_page.url
            else
              page.referer.should be_nil
            end
            previous_page = page
          end
        end

        it "should optionally limit the depth of the crawl" do
          Link.enq(:url => @pages[0].url)
          core = Anemone.crawl(@opts.merge({:depth_limit => 3}))

          Page.count.should == 4
        end
      end
    end

    describe "options" do
      it "should accept options for the crawl" do
        Link.enq(:url => SPEC_DOMAIN)
        core = Anemone.crawl(:verbose => false,
                             :threads => 2,
                             :discard_page_bodies => true,
                             :user_agent => 'test',
                             :obey_robots_txt => true,
                             :depth_limit => 3,
                             :queue_timeout => 3)

        core.opts[:verbose].should == false
        core.opts[:threads].should == 2
        core.opts[:discard_page_bodies].should == true
        core.opts[:delay].should == 0
        core.opts[:user_agent].should == 'test'
        core.opts[:obey_robots_txt].should == true
        core.opts[:depth_limit].should == 3
      end


      it "should use 1 thread if a delay is requested" do
        Link.enq(:url => SPEC_DOMAIN)
        Anemone.crawl(:delay => 0.01, :threads => 2, :queue_timeout => 2).opts[:threads].should == 1
      end
    end
  end
end
