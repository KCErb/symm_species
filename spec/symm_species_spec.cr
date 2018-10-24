require "./spec_helper"

module SymmSpecies
  describe SymmSpecies do
    # smoke test
    describe LIST do
      it "'s an array constant with 212 members'" do
        LIST.size.should eq 212
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
