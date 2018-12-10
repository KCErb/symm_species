module SymmSpecies
  # The orientation of a `child` point group within a `parent` point group.
  #
  # `#correspondence` is an array of `Tuple`s, paired to show how
  # each child direction is mapped to a parent direction.
  #
  # For example, consider point group `2` and its orientations in `422`.
  # The 2-fold axis of `2` could either correspond to the axial 2-fold
  # axis in `422` or the planar one. Thus for the axial orientation the
  # correspondence array would have: { Z, Z } and for the planar orientation
  # it would have { Z, T0 } since T0 is the default orientation in this situation.
  #
  # Two important things to note here:
  # 1. In 422, there are 3 other planar 2-fold axes we could have chosen.
  #   These are all equivalent from the perspective of the parent (422).
  # 2. In the above mappings I wrote { Z, T0 } for convenience. The map
  #   is actually between
  # [`Symm32::Direction`](https://crystal-symmetry.gitlab.io/symm32/Symm32/Direction.html)s
  #  which are a bit more complex then the simple name of a
  # [Symm32::Axis](https://crystal-symmetry.gitlab.io/symm32/Symm32/Axis.html).
  struct Orientation
    getter child : PointGroup
    getter parent : PointGroup

    # correspondence of child direction to parent direction,
    # { child, parent }
    # i.e. `correspondence.first` will often be the following tuple:
    # {child's Z, parent's Z)}
    # or if the child's z direction is in the paren't plane:
    # {child's z-direction, parent's T0}
    property correspondence = Array(Tuple(Direction, Direction)).new

    # Parent's classification ([`Symm32::AxisKind`](https://crystal-symmetry.gitlab.io/symm32/Symm32/AxisKind.html))
    # of the direction in which the child has
    # placed its z-axis.
    #
    # The child is oriented with its z-axis along some direction
    # in the parent (if it has any directions at all that is).
    # The parent possesses a classification for this direction.
    # In the example given in this class's "Overview" we considered 2 in
    # 422. In the axial orientation, the `axial_classification` would be
    # `AxisKind::Axial`, in the planar orientation, because the child's
    # Z-direction is in the plane, the `axial_classification` would be
    # `AxisKind::Planar`
    property dir1_classification = AxisKind::None

    # Similar to `dir1_classification`. This is an [`Symm32::AxisKind`](https://crystal-symmetry.gitlab.io/symm32/Symm32/AxisKind.html) which
    # communicates how the parent group views the orientation of the child's
    # T-plane.
    #
    # Once the child's Z-axis has been placed in the parent, the only degree
    # of freedom remaining is the rotation of its T-plane elements about
    # that axis. We can consider the first T-plane axis (usually T0) and
    # determine parent's classification of that direction.
    property dir2_classification = AxisKind::None

    alias Fingerprint = Hash(AxisKind, Set(Symbol))

    def initialize(@child, @parent, first_pair = nil)
      if first_pair
        child_dir1, parent_dir1 = first_pair
        correspondence << first_pair
        @dir1_classification = parent_dir1.classification
      end
    end

    # Attempts to use the first two pairs in the correspondence
    # array to determine the correspondence of remaining axes.
    # If it was successful, it returns the orientation, if not
    # it returns nil.
    def complete?(second_pair)
      # Update obj properties from second_pair
      correspondence << second_pair
      @dir2_classification = second_pair.last.classification

      # Use the current state of obj to determine coordinate transform
      # between the two systems
      child_axes = correspondence.map(&.first.axis.normalized)
      parent_axes = correspondence.map(&.last.axis.normalized)

      # find axis and rotation angle between first pair
      axis = child_axes.first.cross(parent_axes.first)
      angle = Math.acos(child_axes.first.dot(parent_axes.first))
      rot1 = RotationMatrix.new(axis, angle)

      # find axis and rotation angle between second pair
      rotated_child = rot1 * child_axes.last
      axis = rotated_child.cross(parent_axes.last)
      angle = Math.acos(rotated_child.dot(parent_axes.last))
      rot2 = RotationMatrix.new(axis, angle)
      rot3 = rot2 * rot1

      remaining_directions = child.directions - correspondence.map(&.first)
      remaining_directions.each do |child_dir|
        parent_coords = rot3 * child_dir.axis.coordinates
        parent_dir = parent.select_direction(parent_coords)
        break unless parent_dir
        correspondence << {child_dir, parent_dir}
      end
      correspondence.size == child.directions.size ? self : nil
    end

    def clone
      self.class.new(@child, @parent, @correspondence.first)
    end

    # Determine if an orientation could be considered a "subset" of this one.
    #
    # Self is a subset of other if:
    # 1. They share the same parent
    # 2. Self can be oriented within other and retain orientation within parent.
    #
    # Example: orientation of 4 within 4/mmm requires z orientation of 4
    # orientation of 2 within 4 requires z orientation of 2, but orientation of 2
    # within 4/mmm can be either in z (2|) or in plane (2_). Thus 2|
    # is a subset of 4 (wrt 4/mmm) but 2_ is not.
    def subset?(other : Orientation)
      return false if parent != other.parent
      return false unless Cardinality.fits_within?(child, other.child) # origin cardinality
      return true if correspondence.empty?                             # if no dir, then origin check was enough

      # ensure that for all directions an equivalent direction can be found
      # in other (equiv. wrt. common parent). Thus we delete as we find
      # to make sure they all get their own. This is a quick and dirty
      # solution to the harder "marriage problem":
      # https://en.wikipedia.org/wiki/Hall%27s_marriage_theorem
      candidates = other.correspondence.dup
      correspondence.each do |child_dir, parent_dir|
        top_dirs = candidates.select do |_, top_parent_dir|
          parent_dir.classification == top_parent_dir.classification
        end
        # requests << top_dirs.select do |top_child_dir, _|
        dir = top_dirs.find do |top_child_dir, _|
          Cardinality.fits_within?(child_dir, top_child_dir)
        end
        dir ? candidates.delete(dir) : return false
      end
      true
    end

    # returns a string distinguishing this orientation from others
    def fingerprint
      fingerprint = Fingerprint.new
      if correspondence.empty?
        fingerprint[AxisKind::None] = child.isometries.map(&.kind).to_set
      else
        groups = correspondence.group_by { |_, parent| parent.classification }
        groups.each do |classification, corr_arr|
          kinds = corr_arr.flat_map { |c, p| c.kinds.to_a }.to_set
          fingerprint[classification] = kinds
        end
      end
      fingerprint
    end

    # determine if the two axes of the parent are distinguishable
    private def axes_indistinguishable?
      first_two = correspondence[0, 2]
      indistinguishable = first_two.size == 2 &&
                          first_two[0].last.kinds == first_two[1].last.kinds
    end

    def_hash fingerprint

    def ==(other : Orientation)
      fingerprint == other.fingerprint
    end
  end
end
