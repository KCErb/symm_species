module SymmSpecies
  # Class for calculating the possible orientations of a child
  # `PointGroup` within a parent [`PointGroup`](https://crystal-symmetry.gitlab.io/symm32/Symm32/PointGroup.html).
  class OrientationFactory
    getter child : PointGroup
    getter parent : PointGroup
    @child_plane : Array(Direction)

    def initialize(@child, @parent)
      @orientations = [] of Orientation
      @child_plane = child.plane
    end

    # Calculates the orientations of `#child` within `#parent`. Returns
    # an array of `Orientation`s.
    def calculate_orientations
      return @orientations unless Cardinality.fits_within?(child, parent)
      child_z_direction = child.select_direction(Axis::Z)
      return handle_no_z unless child_z_direction

      # iterate through parent directions, finding possible orientations of
      # child's Z axis and subsequently its T plane in the parent
      parent.directions.each do |parent_direction|
        next unless is_valid?(parent_direction, child_z_direction)
        build_orientations_in(parent_direction)
      end
      @orientations.uniq!
    end

    # The child has no z, so we return a special orientation for identity and
    # inversion groups which has a nil "parent_direction"
    private def handle_no_z
      [Orientation.new(child, parent)]
    end

    # this orientation is unique from parent's perspective?
    # this orientation fits cardinality-wise?
    private def is_valid?(parent_direction, child_z_direction)
      valid = true
      valid &= is_unique?(parent_direction)
      valid &= Cardinality.fits_within?(child_z_direction, parent_direction)
    end

    private def build_orientations_in(parent_direction)
      orientation = Orientation.new(child, parent, parent_direction)
      return @orientations << orientation if @child_plane.empty?
      orient_remaining(orientation, parent_direction)
    end

    # orient the rest of the child elements somewhere in the parent
    private def orient_remaining(orientation, parent_direction)
      plane_subsets(parent_direction).each do |plane|
        new_orientation = orientation.clone
        new_orientation.complete(plane)
        @orientations << new_orientation if new_orientation.valid?
      end
    end

    # There are two ways the parent plane could fit into the child
    # plane. If they are the same size (method 1 below), then we should
    # just match ABCD => ABCD and then ABCD => BCDA.
    # If they are different size (method 2) then we should alternately
    # select. So the parent's ABCD would get chopped up into two subplane
    # of AC and BD, the result is that if a child had AB in t0 and t90, then
    # that'll get paired with the parent's AC => t0, t90
    # and for the other BD => t45, 135.
    #
    # Thus we have two methods for determining subsets as seen below.
    private def plane_subsets(parent_direction)
      parent_plane = parent.directions_perp_to(parent_direction.axis)
      fits = Cardinality.count_fits_arr(@child_plane, parent_plane)
      return [] of Array(Direction) unless fits > 0

      step_size = parent_plane.size / @child_plane.size

      if step_size == 1
        plane_subsets_method_1(fits, parent_plane)
      else
        plane_subsets_method_2(step_size, parent_plane)
      end
    end

    # See docs for plane_subsets
    # We achieve the ABCD, BCDA pattern by shuffling the array
    # we track classification to ensure parent only returns
    # unique subsets from its perspective
    private def plane_subsets_method_1(fits, parent_plane)
      subsets = [] of Array(Direction)
      classifications = [] of AxisKind
      fits.times do
        classification = parent_plane[0].classification
        next if classifications.includes? classification
        classifications << classification
        subsets << parent_plane.clone
        # shuffle front to back
        last = parent_plane.shift
        parent_plane << last
      end
      subsets
    end

    # See docs for plane_subsets
    # We achieve the AC, BD pattern by the modulus of the index i
    # we track classification to ensure parent only returns
    # unique subsets from its perspective.
    #
    # Also, it turns out that the members of ABCD might have
    # different classifications, so you really must
    # try AC, BD, CA, and DB too. Which is a little tricky. See below.
    private def plane_subsets_method_2(step_size, parent_plane)
      double = parent_plane.concat(parent_plane)
      subsets = [] of Array(Direction)
      classifications = [] of AxisKind
      i = 0
      groups = double.group_by { |dir| i += 1; i % step_size }
      # Go through each doubled subset, ie [ABAB], [CDCD]
      groups.values.each do |doubled_subset|
        # Each cons of the above minus 1 => AB, BA
        doubled_subset[0...-1].each_cons(@child_plane.size) do |plane|
          # Finally we have a plane: AB, or CD, or BA etc
          # For 3 you'd get: ACE, CEA, EAC, BDF, DFB, FBD, get the picture?
          next unless Cardinality.fits_within?(@child_plane, plane)
          classification = plane[0].classification
          next if classifications.includes? classification
          classifications << classification
          subsets << plane
        end
      end
      subsets
    end

    # Does this array of orientations already have an orientation
    # with this parent's classification?
    private def is_unique?(parent_direction)
      index = @orientations.index do |orientation|
        orientation.axis_classification == parent_direction.classification
      end
      index.nil? # if index is nil, then this is unique
    end
  end
end
