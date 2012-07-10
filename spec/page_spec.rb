$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone

  describe "PageStorage" do
    before(:each) do
      Page.remove
      @params = {:url => URI(SPEC_DOMAIN + 'queue'),
        :body => "<html><body>test</body></html>",
        :headers => {"content-type"=>["text/html"]},
        :redirect_to => URI(SPEC_DOMAIN + 'home'),
        :error => 'error',
        :code => 200,
        :response_time => 200,
        :connected_links => [SPEC_DOMAIN + 'link1'],
        :depth => 1,
        :referer => URI(SPEC_DOMAIN + 'referer'),
        :code => 200}
    end

    it "should initalize page object with default values" do
      page = Page.new

      page.depth.should == 0
      page.fetched?.should == false
    end

    it "should create page object" do 
      page = Page.create(@params.clone)

      @params.each do |k,v|
        v = v.to_s if v.kind_of?(URI::HTTP)
        page.send(k).should == v
      end
    end

  end

  describe Page do

    before(:each) do
      FakeWeb.clean_registry
      #Delete page and link collection
      Page.remove
      Link.remove

      @opts = {:link_fetch_attemps => 3}
      @http = Anemone::HTTP.new(@opts)

      Link.enq({:url => FakePage.new('home', :links => '1').url})
      @http.fetch_page(Link.deq)
      @page = Page.deq
    end

    it "should indicate whether it successfully fetched via HTTP" do
      @page.should respond_to(:fetched?)
      @page.fetched?.should == true

      Link.enq({:url => SPEC_DOMAIN + 'fail'})
      @http.fetch_page(Link.deq)

      link = Link[SPEC_DOMAIN + 'fail']
      link.error.should_not be_nil
      link.state.should == Link::NEW
    end

    it "should store and expose the response body of the HTTP request" do
      body = 'test'
      fake_page = FakePage.new('body_test', {:body => body})
      Link.enq({:url => fake_page.url})
      @http.fetch_page(Link.deq)
      page = Page.deq

      page.body.should == body
    end

    it "should record any error that occurs during fetch_page" do
      link = Link.enq({:url => SPEC_DOMAIN + 'error'})
      link.should respond_to(:error) 
      link.error.should be_nil

      @http.fetch_page(Link.deq)

      link = Link[SPEC_DOMAIN + 'error']
      link.error.should_not be_nil
    end

    it "should store the response headers when fetching a page" do
      @page.headers.should_not be_nil
      @page.headers.should have_key('content-type')
    end

=begin
    it "should have an OpenStruct attribute for the developer to store data in" do
      @page.data.should_not be_nil
      @page.data.should be_an_instance_of(OpenStruct)

      @page.data.test = 'test'
      @page.data.test.should == 'test'
    end
=end

    it "should have a Nokogori::HTML::Document attribute for the page body" do
      @page.doc.should_not be_nil
      @page.doc.should be_an_instance_of(Nokogiri::HTML::Document)
    end

    it "should indicate whether it was fetched after an HTTP redirect" do
      @page.should respond_to(:redirect?)

      @page.redirect?.should == false

      Link.enq({:url => FakePage.new('redir', :redirect => 'home').url})
      @http.fetch_pages(Link.deq)

      Page.deq.redirect?.should == true
    end

    it "should have a method to tell if a URI is in the same domain as the page" do
      @page.should respond_to(:in_domain?)

      @page.in_domain?(URI(FakePage.new('test').url)).should == true
      @page.in_domain?(URI('http://www.other.com/')).should == false
    end

    it "should include the response time for the HTTP request" do
      @page.should respond_to(:response_time)
    end

    it "should have the cookies received with the page" do
      @page.should respond_to(:cookies)
      @page.cookies.should == []
    end

    describe "#redirect_to" do
      context "when the page was a redirect" do
        it "returns a URI of the page it redirects to" do
          new_page = Page.new(:url => URI(SPEC_DOMAIN), :redirect_to => URI(SPEC_DOMAIN + '1'))
          redirect = new_page.redirect_to
          redirect.should == SPEC_DOMAIN + '1'
        end
      end
    end

    it "should detect, store and expose the base url for the page head" do
      base = "#{SPEC_DOMAIN}path/to/base_url/"

      Link.enq({:url => FakePage.new('body_test', {:base => base}).url})

      @http.fetch_page(Link.deq)
      page = Page.deq
      page.base.should == URI(base)
      @page.base.should be_nil
    end

    it "should have a method to convert a relative url to an absolute one" do
      @page.should respond_to(:to_absolute)
      
      # Identity
      @page.to_absolute(@page.url).should == URI(@page.url)
      @page.to_absolute("").should == URI(@page.url)
      
      # Root-ness
      @page.to_absolute("/").should == URI("#{SPEC_DOMAIN}")
      
      # Relativeness
      relative_path = "a/relative/path"
      @page.to_absolute(relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")
      
      Link.enq({:url => FakePage.new('home/deep', :links => '1').url})
      @http.fetch_page(Link.deq)
      deep_page = Page.deq
      upward_relative_path = "../a/relative/path"
      deep_page.to_absolute(upward_relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")
      
      # The base URL case
      base_path = "path/to/base_url/"
      base = "#{SPEC_DOMAIN}#{base_path}"
      Link.enq({:url => FakePage.new('home/base', {:base => base}).url})
      @http.fetch_page(Link.deq)
      page = Page.deq
      
      # Identity
      page.to_absolute(page.url).should == URI(page.url)
      # It should revert to the base url
      page.to_absolute("").should_not == URI(page.url)

      # Root-ness
      page.to_absolute("/").should == URI("#{SPEC_DOMAIN}")
      
      # Relativeness
      relative_path = "a/relative/path"
      page.to_absolute(relative_path).should == URI("#{base}#{relative_path}")
      
      upward_relative_path = "../a/relative/path"
      upward_base = "#{SPEC_DOMAIN}path/to/"
      page.to_absolute(upward_relative_path).should == URI("#{upward_base}#{relative_path}")      
    end

    describe "#links" do
      it "should not convert anchors to %23" do
        Link.enq({:url => FakePage.new('', :body => '<a href="#top">Top</a>').url})
        @http.fetch_page(Link.deq)

        page = Page.deq
        page.connected_links.should have(1).link
        page.connected_links.first.to_s.should == SPEC_DOMAIN
      end
    end

  end
end
