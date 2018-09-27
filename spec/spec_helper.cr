require "spec"
require "../src/symm_species"

def orientations_count(child, parent)
  child = Symm32.point_group(child)
  parent = Symm32.point_group(parent)

  factory = SymmSpecies::OrientationFactory.new(child, parent)
  orientations = factory.calculate_orientations
  orientations.size
end
