require 'spec_helper'

module Anemone
  describe Admin::Crawler do

    before(:each) do
      Admin::Crawler.remove
      Admin::Crawler.clear
    end

    it "should register crawler to db" do
      Admin::Crawler.register

      Admin::Crawler.count.should == 1

      crawler = Admin::Crawler.first
      crawler.state.should == Admin::Crawler::RUNNING
      crawler.process_id.should_not nil
      crawler.host_name.should_not nil
      crawler.ip.should_not nil
      crawler.start_at.should_not nil
      crawler.stop_at.should nil
      crawler.error.should nil
    end

    it "should not register more then one time for single process" do
      Admin::Crawler.register
      Admin::Crawler.register

      Admin::Crawler.count.should == 1
    end

    it "should unregister crawler wihout error" do
      Admin::Crawler.register

      Admin::Crawler.unregister
      crawler = Admin::Crawler.first

      crawler.state.should == Admin::Crawler::STOPED
      crawler.stop_at.should_not nil
      crawler.error.should == nil

      #Register crawler with error

    end

    it "should unregister crawler with error" do
      Admin::Crawler.register
      Admin::Crawler.unregister('error')

      Admin::Crawler.first.error.should == 'error'
    end

    describe "OnStart" do

      before(:each) do
         @opts = {:queue_timeout => 10}
      end

      it "should register crawler on start and unregister on stop" do
        pid = fork do
          Anemone.crawl(@opts)
        end

        #Wait for process fork complete
        sleep(1)

        Admin::Crawler.first.state.should == Admin::Crawler::RUNNING

        Process.kill("TERM", pid)
        Process.wait

        Admin::Crawler.first.state.should == Admin::Crawler::STOPED
      end

    end

  end
end
