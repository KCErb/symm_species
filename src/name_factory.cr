module SymmSpecies
  # add symbols to a point-group's name to indicate its orientation
  # for example 222 could become 22+2 or 22\2
  # the tricky part is that a point group element can
  # have more than one character, for example 4b'/m' is
  # just 1 direction, one "element" for naming purposes.
  module NameFactory
    # Convert string name to isometry kind symbol
    STR_TO_SYM = {
      "m'" => :anti_mirror,
      "m"  => :mirror,
      "2'" => :anti_rotation_2,
      "2"  => :rotation_2,
    }

    # Considers the non-unique names among members of a summit family
    # and then uses those to distinguish species belonging
    # to that family.
    #
    # The general idea is that if there are just 2, then we need 1 symbol to
    # distinguish them. If 3 or 4 we need 2. So we have two passes here.
    def self.generate_names(non_magnetic = false)
      groups_list = non_magnetic ? Symm32::POINT_GROUPS : SymmMagnetic::POINT_GROUPS
      species_list = non_magnetic ? NON_MAGNETIC_SPECIES : MAGNETIC_SPECIES

      # Determine the summit of each family since that determines uniqueness
      # among children
      summits = Hash(Symm32::Family, Symm32::PointGroup).new
      Symm32::Family.each do |family|
        point_groups = groups_list.select { |pg| pg.family == family }
        summits[family] = point_groups.sort_by(&.isometries.size).last
      end

      # generate name maps, the key here has type species::fingerprint, but
      # we're not keying by species fingerprint (hence this note). The tricky
      # part is that we can use that data structure to create an equivalence
      # class among species, we are just replacing the standard idea of a species
      # fingerprint with this non-standard one where we always use the summit as
      # the parent. ye be warned.
      name_map = Hash(Species::Fingerprint, String).new
      summits.each do |_, summit|
        # For each summit find duplicate names, i.e. duplicate child_names
        # and set one or two symbols on them to distinguish
        species_arr = SymmSpecies.species_for(parent: summit, non_magnetic: non_magnetic)

        duplicate_names(species_arr).each do |arr_of_same|
          label_dir1(arr_of_same, name_map, summit)
        end

        duplicate_names(species_arr).each do |arr_of_same|
          # guard against labelling 3-fold axis with x-axis label in cubic
          # this is an edge case which I don't need to handle at the moment
          # I just realized that the logic here will handle incorrectly.
          if arr_of_same.first.child.family == Symm32::Family::Cubic
            raise "cannot label second direction for cubic child"
          end
          label_dir2(arr_of_same, name_map, summit)
        end
      end

      # Now label everything else
      species_list.each do |species|
        # skip if parent is a summit
        next if summits.values.includes?(species.parent)
        summit = summits[species.parent.family]
        if name = name_map[{summit, species.child, species.orientation.fingerprint}]?
          species.child_name = name
        end
      end
    end

    # Determine label that dir1 should have and apply if it will
    # help differentiate species
    private def self.label_dir1(arr_of_same, name_map, summit)
      symbols = arr_of_same.map do |species|
        sym = species.orientation.dir1_classification.symbol
      end
      # only label dir1 if it will make the names unique
      if arr_of_same.size > 2 || symbols.uniq.size > 1
        arr_of_same.zip(symbols) do |species, sym|
          idx = child_name_first_index(species)
          new_name = species.child_name.insert(idx, sym)
          assign_name(species, new_name, name_map, summit)
        end
      end
    end

    # finds index to insert first label in the name
    private def self.child_name_first_index(species)
      name = species.child_name
      parts = name_to_parts(name)
      # find last part of name that is the z specifier, i.e. m' in the above idx = 2
      slash_idx = parts.index("/")
      idx = slash_idx ? slash_idx + 1 : 0
      # Get length of that part of the string
      z_string = parts[0..idx].join("")
      z_string.size
    end

    # Determine label dir2 should have and apply it.
    private def self.label_dir2(arr_of_same, name_map, summit)
      arr_of_same.each do |species|
        sym = species.orientation.dir2_classification.symbol
        idx = child_name_second_index(species)
        new_name = species.child_name.insert(idx, sym)
        assign_name(species, new_name, name_map, summit)
      end
    end

    private def self.child_name_second_index(species)
      name = species.child_name
      name = name[0..-3] if name.includes?("1'")
      parts = name_to_parts(name)
      # find last part of name that is the z specifier, i.e. m' in the above idx = 2
      z_string = parts[0..-2].join("")
      z_string.size
    end

    # Split name into parts like this: "4b'/m'+mm" becomes
    # ["4b'", "/", "m'+", "m", "m"]
    def self.name_to_parts(name)
      name.scan(/(\db'|\db|\w'|\w|\/)(\||\_|\+|\\)?/m).map(&.[0])
    end

    private def self.assign_name(species, name, name_map, summit)
      species.child_name = name
      name_map[{summit, species.child, species.orientation.fingerprint}] = name
    end

    # Takes an array of objects which have a `name` property and
    # returns an array of arrays, where each sub array contains the objects
    # with the same name. All entries have size > 1
    private def self.duplicate_names(arr)
      arr.group_by(&.name)
        .select { |k, v| v.size > 1 }
        .values
    end
  end
end
