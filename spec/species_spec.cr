require "./spec_helper"

module SymmSpecies
  describe Species do
    it "has a number" do
      LIST[0].number.should eq 1
    end

    it "has a name" do
      LIST[0].name.should eq "1b > 1"
      LIST[177].name.should eq "4b3m > m\\"
    end

    it "counts number of orientational domains correctly" do
      SymmSpecies.number(155).n_domain.should eq 6
    end

    it "can compute child's directions in parent's orientation" do
      # 4b2m > 2|  so the 2 is the only child dir and in parent it is Z
      species = SymmSpecies.number(45)
      z_dir = species.reoriented_child.first
      z_dir.axis.should eq Axis::Z

      # 4b2m > 2_  so the 2 is the only child dir and in parent it is in T plane
      species = SymmSpecies.number(46)
      z_dir = species.reoriented_child.first
      z_dir.axis.should eq Axis::T0
    end

    describe "#child_name" do
      it "determines child_name for species 4" do
        species = SymmSpecies.number(4)
        species.child_name.should eq "m"
      end

      it "determines child_name for species 27" do
        species = SymmSpecies.number(27)
        species.child_name.should eq "m|"
      end

      it "determines child_name for species 154" do
        species = SymmSpecies.number(154)
        species.child_name.should eq "2+m+m"
      end

      it "determines child_name for species 176" do
        species = SymmSpecies.number(176)
        species.child_name.should eq "2+m\\m"
      end
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
