require "./spec_helper"
require "../src/crystalfuse/handle_table" # opt-in helper, not loaded by default

describe Crystalfuse::HandleTable do
  it "mints unique handles, fetches, and frees them" do
    t = Crystalfuse::HandleTable(String).new
    a = t.add("alpha")
    b = t.add("beta")

    a.should_not eq(b)
    t[a].should eq("alpha")
    t[b]?.should eq("beta")
    t.size.should eq(2)

    t.delete(a).should eq("alpha")
    t[a]?.should be_nil
    t.size.should eq(1)
  end
end
