require "spec"
require "../src/symm_species"

# count number of orientations, used in orientation_factory_spec
def orientations_count(child, parent)
  child = Symm32.point_group(child)
  parent = Symm32.point_group(parent)

  factory = SymmSpecies::OrientationFactory.new(child, parent)
  orientations = factory.calculate_orientations
  orientations.size
end

def test_orientation(child = "1b", parent = "222", non_magnetic = true)
  if non_magnetic
    child_pg = Symm32.point_group(child)
    parent_pg = Symm32.point_group(parent)
  else
    child_pg = SymmMagnetic.point_group(child)
    parent_pg = SymmMagnetic.point_group(parent)
  end

  SymmSpecies::Orientation.new(child_pg, parent_pg)
end
