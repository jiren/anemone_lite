require 'spec_helper'

module Anemone
  describe HTTP do

    describe "fetch_page" do
      before(:each) do
        FakeWeb.clean_registry
        Link.remove
        Page.remove
        @params = {:url => SPEC_DOMAIN}
        @opts = {:link_fetch_attemps => 3}
      end

      it "should still return a nil and update link with default status if an exception occurs during the HTTP connection" do
        HTTP.stub!(:refresh_connection).and_raise(StandardError)
        http = Anemone::HTTP.new(@opts)
        http.fetch_page(Link.enq(@params))

        Link.count.should == 1

        link = Link[SPEC_DOMAIN]

        link.state.should == Link::NEW
        link.error.should_not nil
      end

    end
  end
end
