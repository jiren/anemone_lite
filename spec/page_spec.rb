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
          :visited => false,
          :response_time => 200,
          :connected_links => [SPEC_DOMAIN + 'link1'],
          :depth => 1,
          :fetched => true,
          :referer => URI(SPEC_DOMAIN + 'referer'),
          :code => 200}
    end

    it "should initalize page object with default values" do
      page = Page.new
       
      page.depth.should == 0
      page.fetched.should == false
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
      #Delete page collection
      Page.remove

      @http = Anemone::HTTP.new
      @http.fetch_page(FakePage.new('home', :links => '1').url)
      @page = Page.deq
    end

    it "should indicate whether it successfully fetched via HTTP" do
      @page.should respond_to(:fetched?)
      @page.fetched?.should == true

      fail_page = @http.fetch_page(SPEC_DOMAIN + 'fail')
      fail_page.fetched?.should == false
    end

    it "should store and expose the response body of the HTTP request" do
      body = 'test'
      @http.fetch_page(FakePage.new('body_test', {:body => body}).url)
      page = Page.deq
      page.body.should == body
    end

    it "should record any error that occurs during fetch_page" do
      @page.should respond_to(:error)
      @page.error.should be_nil

      fail_page = @http.fetch_page(SPEC_DOMAIN + 'fail')
      fail_page.error.should_not be_nil
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

      @http.fetch_pages(FakePage.new('redir', :redirect => 'home').url)
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

=begin
    describe "#to_hash" do
      it "converts the page to a hash" do
        hash = @page.to_hash
        hash['url'].should == @page.url.to_s
        hash['referer'].should == @page.referer.to_s
        hash['links'].should == @page.links.map(&:to_s)
      end

      context "when redirect_to is nil" do
        it "sets 'redirect_to' to nil in the hash" do
          @page.redirect_to.should be_nil
          @page.to_hash[:redirect_to].should be_nil
        end
      end

      context "when redirect_to is a non-nil URI" do
        it "sets 'redirect_to' to the URI string" do
          new_page = Page.new(URI(SPEC_DOMAIN), {:redirect_to => URI(SPEC_DOMAIN + '1')})
          new_page.redirect_to.to_s.should == SPEC_DOMAIN + '1'
          new_page.to_hash['redirect_to'].should == SPEC_DOMAIN + '1'
        end
      end
    end

    describe "#from_hash" do
      it "converts from a hash to a Page" do
        page = @page.dup
        page.depth = 1
        converted = Page.from_hash(page.to_hash)
        converted.links.should == page.links
        converted.depth.should == page.depth
      end

      it 'handles a from_hash with a nil redirect_to' do
        page_hash = @page.to_hash
        page_hash['redirect_to'] = nil
        lambda{Page.from_hash(page_hash)}.should_not raise_error(URI::InvalidURIError)
        Page.from_hash(page_hash).redirect_to.should be_nil
      end
    end
=end

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
      @http.fetch_page(FakePage.new('body_test', {:base => base}).url)
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
      
      @http.fetch_page(FakePage.new('home/deep', :links => '1').url)
      deep_page = Page.deq
      upward_relative_path = "../a/relative/path"
      deep_page.to_absolute(upward_relative_path).should == URI("#{SPEC_DOMAIN}#{relative_path}")
      
      # The base URL case
      base_path = "path/to/base_url/"
      base = "#{SPEC_DOMAIN}#{base_path}"
      @http.fetch_page(FakePage.new('home/base', {:base => base}).url)
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

  end
end
