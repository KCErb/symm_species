require "./spec_helper"

module SymmSpecies
  describe SymmSpecies do
    describe "getter helpers" do
      describe "non_magnetic" do
        it "can get a species by number" do
          species = SymmSpecies.number(32, non_magnetic: true)
          species.number.should eq 32
          species.parent.should eq Symm32.point_group("422")
          species.child.should eq Symm32.point_group("222")
        end

        it "can get all species for a parent" do
          parent_pg = Symm32.point_group("422")
          species = SymmSpecies.species_for(parent: parent_pg, non_magnetic: true)
          species.size.should eq 5
        end

        it "can get all species for a child" do
          child_pg = Symm32.point_group("422")
          species = SymmSpecies.species_for(child: child_pg, non_magnetic: true)
          species.size.should eq 3
        end

        it "can get species for parent and child" do
          parent_pg = Symm32.point_group("422")
          child_pg = Symm32.point_group("2")
          species = SymmSpecies.species_for(parent: parent_pg, child: child_pg, non_magnetic: true)
          species.size.should eq 2
        end
      end

      describe "default: magnetic" do
        it "can get a species by number" do
          species = SymmSpecies.number(1132)
          species.number.should eq 1132
          species.parent.should eq SymmMagnetic.point_group("2/m'")
          species.child.should eq SymmMagnetic.point_group("2")
        end

        it "can get all species for a parent" do
          parent_pg = SymmMagnetic.point_group("4b2'm'")
          species = SymmSpecies.species_for(parent: parent_pg)
          species.size.should eq 7
        end

        it "can get all species for a child" do
          child_pg = SymmMagnetic.point_group("2'2'2")
          species = SymmSpecies.species_for(child: child_pg)
          species.size.should eq 40
        end

        it "can get species for parent and child" do
          parent_pg = SymmMagnetic.point_group("4'/m'm'm")
          child_pg = SymmMagnetic.point_group("2m'm'")
          species = SymmSpecies.species_for(parent: parent_pg, child: child_pg)
          species.size.should eq 2
        end
      end
    end
  end
end
