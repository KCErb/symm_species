require "symm32"

module SymmSpecies
  VERSION = "1.0.0"

  include Symm32
end

require "./*"

# Namespace for tools that turn the 32 point groups provided by
# [Symm32](https://gitlab.com/crystal-symmetry/symm32) into the 212
# Aizu species.
#
# The primary tool is the concept of an `Orientation` which shows how one
# point group's isometries are oriented with respect to another (if possible).
# These can be created using the `OrientationFactory` which is the workhorse
# of this module, taking any two point groups and determining the possible
# orientations.
module SymmSpecies
  # This is *the* array which holds all of the results of this module (the 212
  # species).
  LIST = [] of Species
  species_counter = 0

  # Calculate the 212 species
  POINT_GROUPS.each do |parent|
    POINT_GROUPS.reverse_each do |child|
      next if parent.name == child.name
      factory = OrientationFactory.new(child, parent)
      orientations = factory.calculate_orientations
      orientations.each do |orient|
        species_counter += 1
        LIST << Species.new(species_counter, orient)
      end
    end
  end

  # Set `child_name` on species that need a special name to distinguish
  NameFactory(SymmSpecies).generate_names(POINT_GROUPS, LIST)

  # Get species by number
  def self.number(num : Int32)
    LIST.select { |species| species.number == num }.first
  end

  # Get species where the parent PointGroup is `parent` if provided
  # and child group is child if provided. If neither provided, returns
  # all species.
  #
  # parent_name or child_name must be a string, the name of the group
  def self.species_for(parent = nil, child = nil)
    LIST.select do |species|
      result = true
      result &= species.parent == parent if parent
      result &= species.child == child if child
      result
    end
  end
end
