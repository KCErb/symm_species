require "./spec_helper"

module SymmSpecies
  describe NameFactory do
    it "should assign a unique name to every magnetic species" do
      arr = MAGNETIC_SPECIES.map(&.name)
      arr.size.should eq arr.uniq.size
    end

    # spot check some names - these are from before the refactor but
    # they're better than nothing :)
    it "determines child_name for non-magnetic species 4" do
      species = SymmSpecies.number(4, non_magnetic: true)
      species.child_name.should eq "m"
    end

    it "determines child_name for non-magnetic species 27" do
      species = SymmSpecies.number(27, non_magnetic: true)
      species.child_name.should eq "m|"
    end

    it "has correct child_name for non-magnetic species 154" do
      species = SymmSpecies.number(154, non_magnetic: true)
      species.child_name.should eq "2+m+m"
    end
  end
end
