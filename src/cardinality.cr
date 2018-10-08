module SymmSpecies
  # This module is a namespace for methods related to working with
  # something that I call `IsometryCardinality`, you can read that page
  # to get more details.
  module Cardinality
    # Cardinality is the number of each "kind" of isometry in a set of isometries.
    #
    # For example, consider the point group 2/m, it has a 2-fold axis,
    # a mirror plane, and a center of inversion. If I'm asked
    # whether the group 222 could be a parent, I can quickly say
    # "no" just from knowing that 222 does not possess a mirror plane.
    # This is the central purpose of keeping track of the cardinality (number)
    # of each "kind" of isometry.
    #
    # And so for that purpose "kind" is the operation the isometry performs without
    # respect to the direction / axis it performs it in. Thus we are interested
    # in "how many" 2-fold axes a group has, not which directions they are in.
    #
    # Here is the IsometryCardinality Hash for mm2:
    #
    # ```
    # {:identity => 1, :rotation_2 => 1, :mirror => 2}
    # ```
    # Those symbols come from the Isometries themselves (see
    # [`SymmBase::Isometry`](https://crystal-symmetry.gitlab.io/symm_base/SymmBase/Isometry.html))
    # and I must confess that I included them in SymmBase for this use case.
    alias IsometryCardinality = Hash(Symbol, Int32)

    # Turn an array of `Isometry`s into an `IsometryCardinality` Hash.
    def self.compute_cardinality(isometries : Set(Isometry))
      by_kind = isometries.group_by { |iso| iso.kind }
      by_kind.map { |k, v| {k, v.size} }.to_h
    end

    # Is child a "subset" of parent (in terms of cardinality)?
    #
    # Subset, in this case, is defined such that for each isometry kind
    # in self, other has at least as many as self.
    def self.fits_within?(child, parent)
      child_card = compute_cardinality(child.isometries)
      parent_card = compute_cardinality(parent.isometries)
      fits_within?(child_card, parent_card)
    end

    # Is child a "subset" of parent (in terms of cardinality)?
    #
    # Subset, in this case, is defined such that for each isometry kind
    # in self, other has at least as many as self.
    def self.fits_within?(child_arr : Array, parent_arr : Array)
      child_card = compute_cardinality_arr(child_arr)
      parent_card = compute_cardinality_arr(parent_arr)
      fits_within?(child_card, parent_card)
    end

    private def self.fits_within?(child : IsometryCardinality, parent : IsometryCardinality)
      child.all? do |kind, count|
        parent[kind]? && parent[kind] >= count
      end
    end

    # Counts number of ways that child can fit into the parent.
    #
    # This is determined by using the smallest number when dividing parent count
    # by child count for each kind. i.e. it is, based on cardinality alone,
    # the maximum number of fits where all of the child isometries get a
    # different element in the parent.
    def self.count_fits_arr(child_arr, parent_arr)
      child_card = compute_cardinality_arr(child_arr)
      parent_card = compute_cardinality_arr(parent_arr)
      count_fits(child_card, parent_card)
    end

    # Helper method to make count_fits_arr more readable. This
    # method, in theory, could be made public, but so far I've only needed
    # `fits_within?` for this kind of input.
    private def self.count_fits(child_card : IsometryCardinality, parent_card : IsometryCardinality)
      return 1_u8 if child_card.empty?
      counts = child_card.compact_map do |kind, count|
        next if kind == :identity || kind == :inversion
        if parent_card[kind]? && parent_card[kind] >= count
          parent_card[kind] / count
        else
          return 0_u8
        end
      end
      counts.sort!
      counts.size > 0 ? counts[0] : 0_u8
    end

    # Converts an array of objects with cardinality into a single
    # IsometryCardinality
    private def self.compute_cardinality_arr(other_arr)
      empty = Set(Isometry).new
      all_isometries = other_arr.reduce(empty) do |acc, other|
        acc | other.isometries
      end
      compute_cardinality(all_isometries)
    end
  end
end
