require "./spec_helper"

module SymmSpecies
  describe SymmSpecies do
    # smoke test
    describe LIST do
      it "'s an array constant with 212 members'" do
        LIST.size.should eq 212
      end
    end

    describe Species do
      it "has a number" do
        LIST[0].number.should eq 1
      end

      it "has a name" do
        LIST[0].name.should eq "1. 1b > 1"
        LIST[151].name.should eq "152. m3b > 3\\"
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
    end

    describe "getter helpers" do
      it "can get a species by number" do
        species = SymmSpecies.number(32)
        species.number.should eq 32
        species.parent.should eq Symm32.point_group("422")
        species.child.should eq Symm32.point_group("222")
      end

      it "can get all species for a parent" do
        parent_pg = Symm32.point_group("422")
        species = SymmSpecies.species_for(parent: parent_pg)
        species.size.should eq 5
      end

      it "can get all species for a child" do
        child_pg = Symm32.point_group("422")
        species = SymmSpecies.species_for(child: child_pg)
        species.size.should eq 3
      end

      it "can get species for parent and child" do
        parent_pg = Symm32.point_group("422")
        child_pg = Symm32.point_group("2")
        species = SymmSpecies.species_for(parent: parent_pg, child: child_pg)
        species.size.should eq 2
      end
    end
  end
end
