module SymmSpecies
  # Class for calculating the possible orientations of a child
  # `PointGroup` within a parent [`PointGroup`](https://crystal-symmetry.gitlab.io/symm32/Symm32/PointGroup.html).
  class OrientationFactory
    getter child : PointGroup
    getter parent : PointGroup

    def initialize(@child, @parent)
      @orientations = [] of Orientation
    end

    # Calculates the orientations of `#child` within `#parent`. Returns
    # an array of `Orientation`s.
    def calculate_orientations
      return @orientations unless Cardinality.fits_within?(child, parent)
      axis1 = Axis::Z
      child_dir1 = child.select_direction(axis1)
      return handle_no_axes unless child_dir1
      # iterate through parent directions, finding possible orientations of
      # child's first axis and subsequently its T plane in the parent
      parent.directions.each do |parent_direction|
        next unless is_valid?(parent_direction, child_dir1)
        build_orientations_for_pair(child_dir1, parent_direction)
      end
      @orientations.uniq
    end

    # The child has no z, so we return a special orientation for identity and
    # inversion groups which has a nil "parent_direction"
    private def handle_no_axes
      [Orientation.new(child, parent)]
    end

    # this orientation is unique from parent's perspective?
    # this orientation fits cardinality-wise?
    private def is_valid?(parent_direction, child_dir1)
      valid = true
      valid &= is_unique?(parent_direction)
      valid &= Cardinality.fits_within?(child_dir1, parent_direction)
    end

    private def build_orientations_for_pair(child_dir1, parent_direction)
      orientation = Orientation.new(child, parent, {child_dir1, parent_direction})
      child_dir2 = child.plane.empty? ? nil : child.plane.first
      return @orientations << orientation unless child_dir2
      orient_axis2(orientation, parent_direction, child_dir2)
    end

    # orient the rest of the child elements somewhere in the parent
    private def orient_axis2(orientation, parent_direction, child_dir2)
      plane = parent.directions_perp_to(parent_direction.axis)
      plane.each do |dir|
        next unless Cardinality.fits_within?(child_dir2, dir)
        new_orientation = orientation.clone
        res = new_orientation.complete?({child_dir2, dir})
        @orientations << res if res
      end
    end

    # Does this array of orientations already have an orientation
    # with this parent's classification?
    private def is_unique?(parent_direction)
      index = @orientations.index do |orientation|
        orientation.dir1_classification == parent_direction.classification
      end
      index.nil? # if index is nil, then this is unique
    end
  end
end
