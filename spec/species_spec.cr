require "./spec_helper"

module SymmSpecies
  describe Species do
    test_species = Species.new(11, test_orientation)

    it "has a number" do
      test_species.number.should eq 11
    end

    it "has a name" do
      test_species.name.should eq "222 > 1b"
    end

    it "counts number of orientational domains correctly" do
      test_species.n_domain.should eq 2
    end

    it "can compute child's directions in parent's orientation" do
      # 4b2m > 2|  so the 2 is the only child dir and in parent it is Z
      species = SymmSpecies.number(45, non_magnetic: true)
      z_dir = species.reoriented_child.first
      z_dir.axis.should eq Symm32::Axis::Z

      # 4b2m > 2_  so the 2 is the only child dir and in parent it is in T plane
      species = SymmSpecies.number(46, non_magnetic: true)
      z_dir = species.reoriented_child.first
      z_dir.axis.should eq Symm32::Axis::T0
    end

    it "has correct child_name for species 176" do
      species = SymmSpecies.number(176, non_magnetic: true)
      species.child_name.should eq "2+m\\m"
    end

    describe "#fingerprint" do
      it "has a fingerprint" do
        species = SymmSpecies.number(154)
        species.fingerprint[0].should eq species.parent
        species.fingerprint[1].should eq species.child
        species.fingerprint[2].should eq species.orientation.fingerprint
      end
    end
  end
end
