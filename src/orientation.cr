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

    # The direction in the parent where the Z direction of the child goes.
    # Parent may not have any direction since directions have axes
    @parent_direction : Direction | Nil

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
    property axis_classification = AxisKind::None

    # Similar to `axis_classification`. This is an [`Symm32::AxisKind`](https://crystal-symmetry.gitlab.io/symm32/Symm32/AxisKind.html) which
    # communicates how the parent group views the orientation of the child's
    # T-plane.
    #
    # Once the child's Z-axis has been placed in the parent, the only degree
    # of freedom remaining is the rotation of its T-plane elements about
    # that axis. We can consider the first T-plane axis (usually T0) and
    # determine parent's classification of that direction.
    #
    # In practice, this only is relavent for cubic parents.
    property plane_classification = AxisKind::None

    # A little flag for marking orientations as bad, used by the factory
    # to help toss out an orientation that fails checks.
    property? valid = true

    def initialize(@child, @parent, parent_direction = nil)
      @parent_direction = parent_direction
      if parent_direction
        child_z_direction = child.select_direction(Axis::Z)
        @correspondence << {child_z_direction, parent_direction} if child_z_direction
        @axis_classification = parent_direction.classification
      end
    end

    # How should the parent adjust the name of the child to give it
    # a distinct name based on orientation?
    #
    # For example, if the parent
    # is 422 it has 2 children for point group 2. So it will name
    # the one oriented along the axis "2|" and the one oriented in
    # the plane "2_". These strings come from `AxisKind#symbol`
    def child_name
      name = child.name
      name += axis_classification.symbol
      name += plane_classification.symbol if parent.family.cubic?
      name
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
      return true unless @parent_direction                             # if no dir, then origin check was enough

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

    # Complete the correspondence between parent and child using an array of parent
    # directions which map to the child's planar directions. The `OrientationFactory`
    # is used for generating the `parent_plane` in a useful order.
    # This method will mark an orientation as invalid if the
    # suggested mapping doesn't actually work.
    def complete(parent_plane)
      child_plane = child.plane
      raise "Plane is wrong size." if parent_plane.size != child_plane.size
      orient_plane(child_plane, parent_plane)
      handle_cubic(parent_plane) if child.family.cubic?
      @plane_classification = parent_plane.first.classification
    end

    private def orient_plane(child_plane, parent_plane)
      child_plane.each_with_index do |child_dir, index|
        @correspondence << {child_dir, parent_plane[index]}
      end
    end

    # finds new basis vectors relative to orientation of x and z
    private def handle_cubic(parent_plane)
      z_hat = @parent_direction.not_nil!.axis.normalized
      x_hat = parent_plane.first.axis.normalized
      y_hat = z_hat.cross x_hat
      orient_non_planar(x_hat, y_hat, z_hat)
    end

    # looks at each diag/edge direction and converts it in the new coords
    # to determine if parent has a direction parallel to this axis
    # marks orientation as invalid if orientation can't be completed
    private def orient_non_planar(x_hat, y_hat, z_hat)
      non_planar = child.edges.concat child.diags
      non_planar.each do |child_dir|
        break unless valid?
        x, y, z = child_dir.axis.values
        parent_coords = x_hat * x + y_hat * y + z_hat * z
        parent_dir = parent.select_direction(parent_coords)
        break self.valid = false unless parent_dir
        @correspondence << {child_dir, parent_dir}
      end
    end

    def clone
      self.class.new(@child, @parent, @parent_direction)
    end

    # Generates a hash for this orientation which is designed to
    # be identical for equivalent orientations.
    #
    # For example, species 422 => 2_ (#34) can have 4 equivalent `Orientation`
    # objects. One for each of the planar axes that the 2-fold axis could
    # correspond to. This method turns that species into the following
    # string:
    #
    # ```text
    #  { Planar => {:rotation_2} }
    # ```
    #
    # The key in the hash is the parent's classification. The value in the
    # hash is a set of all isometry kinds on that *type* of axis. Thus
    # regardless of the order / spatial orientation of the isometries we
    # get identical hashes so long as the same kinds of isometries are in
    # the same "kinds" of places.
    def fingerprint
      fingerprint = {} of AxisKind => Set(Symbol)

      if correspondence.empty?
        # all is on origin
        fingerprint[AxisKind::None] = child.isometries.map(&.kind).to_set
      else
        # sort to axis enum value for consistency
        sorted = correspondence.sort_by { |child, parent| parent.axis.value }

        # make fingerprint - each classification in parent
        # just gets a set of isometry symbols
        groups = sorted.group_by { |_, parent| parent.classification }
        groups.each do |classification, corr_arr|
          kinds = corr_arr.flat_map { |c, p| c.kinds.to_a }.to_set
          fingerprint[classification] = kinds
        end
      end
      fingerprint
    end

    def_hash fingerprint

    def ==(other : Orientation)
      fingerprint == other.fingerprint
    end
  end
end
