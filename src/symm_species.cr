require "symm32"
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
  VERSION = "0.1.0"

  include Symm32

  # Simple struct for associating a number and name with an `Orientation`.
  struct Species
    # Species name, determined by parent.name and `Orientation#child_name`.
    #
    # Examples
    # ```text
    # 145. 6/mmm > 1
    # 146. 23 > 3\
    # 147. 23 > 222++
    # ```
    getter name : String
    getter number : Int32
    getter orientation : Orientation

    def initialize(@number, @orientation)
      @name = "#{number}. #{parent.name} > #{orientation.child_name}"
    end

    # Returns the result of calling this method on `#orientation`.
    delegate child, parent, to: @orientation

    # Number of orientational domain states. Mathematically the concept is very
    # simple: `parent.order / child.order`. In terms of symmetry the idea is a bit
    # more rich but I won't go into too much detail here, the basic idea is
    # that if you're breaking the symmetry of an object to go from parent to child
    # `n_domain` returns the number of unique ways this can be done.
    def n_domain
      parent.order / child.order
    end

    # Array of child directions where the axis has been changed
    # to the parent's axis.
    def reoriented_child
      orientation.correspondence.map do |child_dir, parent_dir|
        Direction.new(parent_dir.axis, child_dir.isometries)
      end
    end
  end

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

  # Get species by number
  def self.number(num : Int32)
    LIST.select { |species| species.number == num }.first
  end

  # Get species where the parent PointGroup is `parent`.
  def self.species_for(parent : PointGroup)
    LIST.select { |species| species.parent == parent }
  end
end
