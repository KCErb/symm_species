require "symm32"
require "symm_magnetic"

require "./*"
require "./symm_species/*"

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
  VERSION = "1.0.0"

  # Get species by number
  def self.number(num : Int32, non_magnetic = false)
    list = non_magnetic ? NON_MAGNETIC_SPECIES : MAGNETIC_SPECIES
    arr = list.select { |species| species.number == num }
    raise "invalid species number #{num} for #{non_magnetic ? "NON_" : ""}MAGNETIC_SPECIES" if arr.empty?
    arr.first
  end

  # Get species where the parent PointGroup is `parent` if provided
  # and child group is child if provided. If neither provided, returns
  # all species.
  #
  # parent_name or child_name must be a string, the name of the group
  def self.species_for(parent = nil, child = nil, non_magnetic = false)
    list = non_magnetic ? NON_MAGNETIC_SPECIES : MAGNETIC_SPECIES
    list.select do |species|
      result = true
      result &= species.parent == parent if parent
      result &= species.child == child if child
      result
    end
  end

  def self.by_fingerprint(fingerprint : Species::Fingerprint, non_magnetic = false)
    list = non_magnetic ? NON_MAGNETIC_SPECIES : MAGNETIC_SPECIES
    arr = list.select { |species| species.fingerprint == fingerprint }
    raise "invalid fingerprint #{fingerprint} for SymmSpecies" if arr.empty?
    arr.first
  end
end
