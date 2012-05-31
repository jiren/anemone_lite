$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone
  describe Queue do

    describe "PageQueue" do

      before(:each) do
        Page.remove
        @params = {:url => URI(SPEC_DOMAIN + 'queue'),
          :body => "<html><body>test</body></html>",
          :depth => 1,
          :referer => URI(SPEC_DOMAIN + 'referer'),
          :code => 200}
      end

      it "should add page to db queue" do
        Page.enq(@params)

        page = Page.deq
        page.url.should ==  @params[:url].to_s
        page.state.should == Page::PROCESSED
      end

      it "should not add duplicate pages to queue" do
        Page.enq(@params)
        Page.enq(@params)
       
        Page.count.should == 1

      end

    end

    describe "LinkQueue" do
      before(:each) do
        Link.remove
        @params = {:url => URI(SPEC_DOMAIN + 'queue'),
          :page_url => URI(SPEC_DOMAIN + 'page'),
          :depth => 1,
          :referer => URI(SPEC_DOMAIN + 'referer')}
      end

      it "should add links to queue" do
        Link.enq @params

        link  = Link.first
        link.url.should == SPEC_DOMAIN + 'queue'
        link.state.should == Link::NEW
      end

      it "should add links to queue without duplication" do
        Link.enq @params
        Link.enq @params

        Link.count.should == 1
      end

      it "should deq link from queue and update state to processed" do
        Link.enq @params

        link = Link.deq
        link.state.should == Link::PROCESSED
      end

    end
  end
end
