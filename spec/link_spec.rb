$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone
  describe Link do

    before(:each) do
      #Delete link collection
      Link.remove
    end

    it "should initalize link object with url and default values" do
      link = Link.new(:url => URI(SPEC_DOMAIN), 
               :page_url => URI(SPEC_DOMAIN + 'page'))

      link.url.should == SPEC_DOMAIN
      link.page_url.should == SPEC_DOMAIN + 'page'
      
      #Default depth should be 0
      link.depth.should == 0

      link.referer.should == nil
    end

    it "shold create link object to db" do
      Link.create(:url => URI(SPEC_DOMAIN + 'create'), 
                  :page_url => URI(SPEC_DOMAIN + 'page'),
                  :depth => 1,
                  :referer => URI(SPEC_DOMAIN + 'referer'))


      link = Link.first
      link.url.should   == SPEC_DOMAIN + 'create'
      link.page_url.should == SPEC_DOMAIN + 'page'
      link.depth.should  == 1
      link.referer.should == SPEC_DOMAIN + 'referer'

    end

  end
end