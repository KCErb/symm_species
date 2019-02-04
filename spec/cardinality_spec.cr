require "./spec_helper"

module SymmSpecies
  class Foo
    getter isometries = Set(SymmBase::Isometry).new

    def initialize(isometries_arr)
      isometries_arr.each { |iso| @isometries << iso }
    end
  end

  ISO0 = Symm32::PointIsometry.parse("e")
  ISO1 = Symm32::Mirror.new(Symm32::Axis::Z)
  ISO2 = Symm32::Mirror.new(Symm32::Axis::T90)
  ISO3 = Symm32::Rotation.new(Symm32::Axis::T0, 2)
  ISO4 = Symm32::Rotation.new(Symm32::Axis::Z, 2)
  ISO5 = Symm32::Rotation.new(Symm32::Axis::D1, 3)

  ISOMETRIES1 = [ISO0, ISO1, ISO2, ISO3, ISO4]
  ISOMETRIES2 = [ISO0, ISO1, ISO3]
  ISOMETRIES3 = [ISO0, ISO2, ISO4]

  foo1 = Foo.new(ISOMETRIES1)
  foo2 = Foo.new(ISOMETRIES2)
  foo3 = Foo.new(ISOMETRIES3)
  foo_empty = Foo.new([] of SymmBase::Isometry)

  describe Cardinality do
    it "computes cardinality correctly" do
      Cardinality.compute_cardinality(foo1.isometries)[:mirror].should eq 2
      Cardinality.compute_cardinality(foo2.isometries)[:mirror].should eq 1
    end

    it "#fits_within when true" do
      Cardinality.fits_within?(foo2, foo1).should be_true
    end

    it "#fits_within when false" do
      Cardinality.fits_within?(foo1, foo2).should be_false
    end

    describe "#count_fits_arr" do
      # Note, many of these methods use arrays with just one element
      # I left this alone during refactor because it seems fine, but
      # it was motivated by laziness so it might need rethinking.
      it "has 1 fit when child is empty" do
        Cardinality.count_fits_arr([foo_empty], [foo2]).should eq 1
      end

      it "has 0 fits when child does not fit" do
        Cardinality.count_fits_arr([foo1], [foo2]).should eq 0
      end

      it "has 1 fit when child fits one way" do
        Cardinality.count_fits_arr([foo3], [foo2]).should eq 1
      end

      it "has 2 fits when child fits two ways" do
        Cardinality.count_fits_arr([foo2], [foo1]).should eq 2
      end

      it "flattens arrays of isometries and computes on them too" do
        Cardinality.count_fits_arr([foo2, foo3], [foo1]).should eq 1
      end
    end
  end
end
