require "./spec_helper"

describe Crystalfuse::Binding do
  # TODO: Write tests

  it "Operations struct is correct size." do
    size = sizeof(Operations)
    size.should eq(636)
  end

end
