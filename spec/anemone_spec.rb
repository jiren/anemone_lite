$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe Anemone do

  it "should have a version" do
    Anemone.const_defined?('VERSION').should == true
  end

  it "should return a Anemone::Core from the crawl" do
    result = Anemone::Core.new()
    result.should be_an_instance_of(Anemone::Core)
  end

end
