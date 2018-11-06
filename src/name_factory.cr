module SymmSpecies
  module NameFactory(T)
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
    def self.generate_names(groups_list, species_list)
      # Determine the summit of each family since that determines uniqueness
      # among children
      summits = Hash(Family, PointGroup).new
      Family.each do |family|
        point_groups = groups_list.select { |pg| pg.family == family }
        summits[family] = point_groups.sort_by(&.isometries.size).last
      end

      # generate name maps, the key here is a combination of pointgroup
      # and species fingerprint because each species will have more than
      # on name depending on the summit.
      name_map = Hash({PointGroup, PointGroup, Orientation::Fingerprint}, String).new
      summits.each do |_, summit|
        # For each summit find duplicate names, i.e. duplicate child_names
        # and set one or two symbols on them to distinguish
        species_arr = T.species_for(parent: summit)
        duplicate_names(species_arr).each do |arr_of_same|
          label_z(arr_of_same, name_map, summit)
          # arr_of_name_parts = name_to_symbols(arr_of_same)
          # names_arr = determine_unique_names(arr_of_name_parts)
          # assign_names(arr_of_same, names_arr, summit, name_map)
        end
        duplicate_names(species_arr).each do |arr_of_same|
          label_x(arr_of_same, name_map, summit)
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

    # Determine label that z axis should have and apply if it will
    # help differentiate species
    private def self.label_z(arr_of_same, name_map, summit)
      symbols = arr_of_same.map do |species|
        sym = species.orientation.axis_classification.symbol
      end
      # only label z axis if it will make the names unique
      if arr_of_same.size > 2 || symbols.uniq.size > 1
        arr_of_same.zip(symbols) do |species, sym|
          idx = child_name_z_index(species)
          new_name = species.child_name.insert(idx, sym)
          assign_name(species, new_name, name_map, summit)
        end
      end
    end

    # finds index to insert a z label in the name using the species
    # crystal family / Hermann-Mauguin standard name conventions
    private def self.child_name_z_index(species)
      name = species.child_name
      if species.child.family == Family::Orthorhombic
        name.includes?("1'") ? -3 : -1
      else
        parts = name_to_parts(name)
        # find last part of name that is the z specifier, i.e. m' in the above idx = 2
        slash_idx = parts.index("/")
        idx = slash_idx ? slash_idx + 1 : 0
        # Get length of that part of the string
        z_string = parts[0..idx].join("")
        z_string.size
      end
    end

    # Determine label x direction should have and apply it.
    private def self.label_x(arr_of_same, name_map, summit)
      arr_of_same.each do |species|
        sym = species.orientation.plane_classification.symbol
        idx = child_name_x_index(species)
        new_name = species.child_name.insert(idx, sym)
        assign_name(species, new_name, name_map, summit)
      end
    end

    private def self.child_name_x_index(species)
      name = species.child_name
      if species.child.family == Family::Orthorhombic
        name[1] == "'" ? 2 : 1
      else
        name = name[0..-3] if name.includes?("1'")
        parts = name_to_parts(name)
        # find last part of name that is the z specifier, i.e. m' in the above idx = 2
        z_string = parts[0..-2].join("")
        z_string.size
      end
    end

    # Split name into parts like this: "4b/m'mm" becomes ["4b", "/", "m'", "m", "m"]
    private def self.name_to_parts(name)
      name.scan(/(\db|\w'|\w|\/)/m).map(&.[0])
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
