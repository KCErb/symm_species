require "../spec_helper"

module SymmSpecies
  describe SymmSpecies do
    describe NON_MAGNETIC_SPECIES do
      it "'s an array constant with 212 members'" do
        NON_MAGNETIC_SPECIES.size.should eq 212
      end
    end
  end
end
