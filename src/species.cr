module SymmSpecies
  # Simple struct for associating a number and name with an `Orientation`.
  class Species
    getter number : Int32
    getter orientation : Orientation
    property child_name : String
    alias Fingerprint = {Symm32::PointGroup, Symm32::PointGroup, Orientation::Fingerprint}

    def initialize(@number, @orientation)
      @child_name = @orientation.child.name
    end

    # Species name, determined by parent.name and `Orientation#child_name`.
    #
    # Examples
    # ```text
    # 23 > 3
    # 23 > 2+22
    # ```
    def name
      "#{parent.name} > #{child_name}"
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
        Symm32::Direction.new(parent_dir.axis, child_dir.isometries)
      end
    end

    # Returns a unique identifier for this species among all
    # species since the orientation fingerprint is unique only
    # for a specific parent-child combination. note the type:
    # Tuple(String, String, Fingerprint)
    def fingerprint : Fingerprint
      {parent, child, orientation.fingerprint}
    end

    def to_s(io)
      io << "#<Species @number=#{number} @name=\"#{name}\" >"
    end

    def inspect
      to_s
    end
  end
end
