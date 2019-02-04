module SymmSpecies
  MAGNETIC_SPECIES = [] of Species
  # Calculate the 1602 species in a special order
  counter = 0
  SymmMagnetic.gray_groups.each do |parent|
    SymmMagnetic.gray_groups.reverse_each do |child|
      next if parent.name == child.name
      counter = calc_species(parent, child, counter)
    end
  end

  SymmMagnetic.gray_groups.each do |parent|
    SymmMagnetic.bw_groups.reverse_each do |child|
      counter = calc_species(parent, child, counter)
    end
  end

  SymmMagnetic.gray_groups.each do |parent|
    SymmMagnetic.black_groups.reverse_each do |child|
      counter = calc_species(parent, child, counter)
    end
  end

  SymmMagnetic.bw_groups.each do |parent|
    SymmMagnetic.bw_groups.reverse_each do |child|
      next if parent.name == child.name
      counter = calc_species(parent, child, counter)
    end
  end

  SymmMagnetic.bw_groups.each do |parent|
    SymmMagnetic.black_groups.reverse_each do |child|
      counter = calc_species(parent, child, counter)
    end
  end

  SymmMagnetic.black_groups.each do |parent|
    SymmMagnetic.black_groups.reverse_each do |child|
      next if parent.name == child.name
      counter = calc_species(parent, child, counter)
    end
  end

  # Set `child_name` on species that need a special name to distinguish
  NameFactory.generate_names

  private def self.calc_species(parent, child, counter)
    factory = OrientationFactory.new(child, parent)
    orientations = factory.calculate_orientations
    orientations.each do |orient|
      counter += 1
      MAGNETIC_SPECIES << Species.new(counter, orient)
    end
    counter
  end
end
