module SymmSpecies
  NON_MAGNETIC_SPECIES = [] of Species

  # Calculate the 212 non-magnetic species
  counter = 0
  Symm32::POINT_GROUPS.each do |parent|
    Symm32::POINT_GROUPS.reverse_each do |child|
      next if parent.name == child.name
      factory = OrientationFactory.new(child, parent)
      orientations = factory.calculate_orientations
      orientations.each do |orient|
        counter += 1
        NON_MAGNETIC_SPECIES << Species.new(counter, orient)
      end
    end
  end

  # Set `child_name` on species that need a special name to distinguish
  NameFactory.generate_names(non_magnetic: true)
end
