require "../spec_helper"

module SymmSpecies
  describe MAGNETIC_SPECIES do
    it "should be an array of 1602 species" do
      MAGNETIC_SPECIES.size.should eq 1602
    end
  end
end
