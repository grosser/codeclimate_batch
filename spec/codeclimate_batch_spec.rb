require "spec_helper"

describe CodeclimateBatch do
  it "has a VERSION" do
    CodeclimateBatch::VERSION.should =~ /^[\.\da-z]+$/
  end
end
