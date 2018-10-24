require "./spec_helper"

module SymmSpecies
  describe NameFactory do
    # I consider this sufficiently spec'd via the Species
    # specs which check some tricky names.
    it "exists" do
      NameFactory.responds_to?(:generate_names)
    end
  end
end
