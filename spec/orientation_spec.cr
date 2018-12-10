require "./spec_helper"

module SymmSpecies
  describe Orientation do
    it "can be created with a first pair" do
      child = Symm32.point_group("222")
      child_first = child.directions.first
      parent = Symm32.point_group("422")
      parent_first = parent.directions.first
      o = Orientation.new(child, parent, {child_first, parent_first})
      o.child.should eq child
      o.parent.should eq parent
    end

    it "can be created without a parent direction" do
      child = Symm32.point_group("1b")
      parent = Symm32.point_group("222")
      o = Orientation.new(child, parent)
      o.child.should eq child
      o.parent.should eq parent
    end

    it "returns axial classification for nil parent" do
      child = Symm32.point_group("1b")
      parent = Symm32.point_group("222")
      o = Orientation.new(child, parent)
      o.dir1_classification.should eq AxisKind::None
      o.dir2_classification.should eq AxisKind::None
    end

    it "returns plane classifications for parent 422" do
      child = Symm32.point_group("222")
      parent = Symm32.point_group("422")
      parent_first = parent.directions.first
      child_first = child.directions.first
      o = Orientation.new(child, parent, {child_first, parent_first})
      second_pair = {child.directions[1], parent.directions[1]}
      o.complete?(second_pair)
      o.dir2_classification.should eq AxisKind::Planar
    end

    it "maps child with no T plane" do
      child = Symm32.point_group("m")
      child_first = child.directions.first
      parent = Symm32.point_group("2mm")
      parent_first = parent.directions.first
      o = Orientation.new(child, parent, {child_first, parent_first})
      o.correspondence.first[1].should eq parent_first
    end

    describe "#complete" do
      it "completes child with T plane" do
        child = Symm32.point_group("222")
        child_first = child.directions.first
        parent = Symm32.point_group("422")
        parent_first = parent.directions.first
        o = Orientation.new(child, parent, {child_first, parent_first})
        parent_plane = parent.directions_perp_to(Axis::Z)
        o.complete?({child.directions[1], parent_plane[0]})

        # find, then verify
        pair = o.correspondence.find do |o_child, _|
          o_child == child.plane.first
        end.not_nil!

        pair[1].should eq parent_plane.first

        pair = o.correspondence.find do |o_child, _|
          o_child == child.plane[1]
        end.not_nil!

        pair[1].should eq parent_plane[2]

        # check classification too
        o.dir2_classification.should eq AxisKind::Planar
      end

      it "completes cubic child" do
        child = Symm32.point_group("23")
        child_first = child.directions.first
        parent = Symm32.point_group("432")
        parent_first = parent.directions.first
        o = Orientation.new(child, parent, {child_first, parent_first})
        parent_plane = parent.directions_perp_to(Axis::Z)
        o.complete?({child.directions[1], parent_plane[0]})

        pair = o.correspondence.find do |o_child, _|
          o_child == child.diags.first
        end.not_nil!
        pair[1].should eq parent.diags.first

        # check classification too
        o.dir2_classification.should eq AxisKind::OnAxes
      end
    end

    describe "subset?" do
      it "can determine subsets correctly for 4/mmm => 2/m" do
        parent = SymmSpecies.number(51) # 4/mmm => 4/m
        child = SymmSpecies.number(58)  # 4/mmm => 2/m|
        child.orientation.subset?(parent.orientation).should be_true
        child = SymmSpecies.number(59) # 4/mmm => 2/m_
        child.orientation.subset?(parent.orientation).should be_false
      end

      it "can determine subsets correctly for m3bm" do
        parent = SymmSpecies.number(185) # m3bm => 3bm
        child = SymmSpecies.number(188)  # m3bm => 3b
        child.orientation.subset?(parent.orientation).should be_true
        child = SymmSpecies.number(206) # 4/mmm => 2\/m
        child.orientation.subset?(parent.orientation).should be_true
        child = SymmSpecies.number(207) # 4/mmm => m+ - interesting no?
        child.orientation.subset?(parent.orientation).should be_false
        # Neighbors aren't subsets, 198 is not a subset of 199
        parent = SymmSpecies.number(199) # m3bm => mmm+\
        child = SymmSpecies.number(198)  # m3bm => mmm++
        child.orientation.subset?(parent.orientation).should be_false
      end
    end

    # Util methods
    it "can be cloned" do
      child = Symm32.point_group("222")
      child_first = child.directions.first
      parent = Symm32.point_group("422")
      parent_first = parent.directions.first
      o = Orientation.new(child, parent, {child_first, parent_first})
      o2 = o.clone
      o.child.should eq o2.child
      o.parent.should eq o2.parent
      o.correspondence.should eq o2.correspondence
    end

    describe "equality" do
      child = Symm32.point_group("222")
      child_first = child.directions.first
      parent = Symm32.point_group("422")
      parent_first = parent.directions.first
      o = Orientation.new(child, parent, {child_first, parent_first})

      o2 = o.clone
      parent_plane = parent.directions_perp_to(Axis::Z)
      o.complete?({child.directions[1], parent_plane[0]})
      o2.complete?({child.directions[1], parent_plane[1]})

      parent = Symm32.point_group("4/mmm")
      o3 = Orientation.new(child, parent)

      it "generates unique fingerprints for unique orientations" do
        o.fingerprint.should_not eq o3.fingerprint
      end

      it "generates identical fingerprints for non-unique orientations" do
        o.fingerprint.should eq o2.fingerprint
      end

      it "determines equality same as fingerprints" do
        o.should eq o2
      end
    end
  end
end
