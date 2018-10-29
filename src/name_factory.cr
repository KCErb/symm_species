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

      # generate summit maps
      summit_maps = Hash(PointGroup, Array(String)).new
      summits.each do |_, pg|
        # For each summit find duplicate names, i.e. duplicate child_names
        # and set one symbol on them to distinguish
        species_arr = T.species_for(parent: pg)
        duplicate_names(species_arr).each do |arr_of_same|
          summit_maps[pg] = [] of String unless summit_maps.has_key?(pg)
          arr_of_same.each do |species|
            summit_maps[pg] << species.child_name
            set_first_symbol(species)
          end
        end

        # Now do the same again, those that remain need a second symbol
        duplicate_names(species_arr).each do |arr_of_same|
          arr_of_same.each do |species|
            summit_maps[pg] << species.child_name
            set_second_symbol(species)
          end
        end
      end

      # Now label everything else
      species_list.each do |species|
        next if summits.values.includes?(species.parent)
        # find summit for species
        summit = summits[species.parent.family]

        if summit_maps[summit]?
          set_first_symbol(species) if summit_maps[summit].includes? species.child_name
          set_second_symbol(species) if summit_maps[summit].includes? species.child_name
        end
      end
    end

    # Set's the first symbol on a species which needs one.
    #
    # The idea of the algorithm is:
    # 0. Use \ or _ if possible, otherwise + or |
    # 1. Mark the first 2 in the name, m if no 2 present
    private def self.set_first_symbol(species)
      # Split name into parts like this: "4bm'm" becomes ["4b", "m'", "m"]
      parts = species.child_name.scan(/(\db|\w|\/)'?/m).map(&.[0])

      # Find the first 2 (or m if no 2 is present), prime after not
      idx = parts.index("2") ||
            parts.index("m") ||
            parts.index("2'") ||
            parts.index("m'")

      raise "cannot determine unique name if no 2 or m in name" unless idx
      idx += 1
      set_name(species, parts, idx)
    end

    # Set's the second symbol for species where 1 just wasn't enough.
    #
    # In this algorithm we use the same rule 0 as in set_first_symbol.
    private def self.set_second_symbol(species)
      parts = species.child_name.scan(/(\db|\w|\/|\+|\\|\||_)'?/m).map(&.[0])

      idx_sym = parts.index("+") ||
                parts.index("\\") ||
                parts.index("|") ||
                parts.index("_")
      raise "nil?" unless idx_sym
      tmp_parts = parts.dup
      tmp_parts[idx_sym - 1, 2] = ["", ""]
      # idx = parts.index("m") ||
      #       parts.index("m'") ||
      #       parts.index("2") ||
      #       parts.index("2'")
      idx = tmp_parts.index("2") ||
            tmp_parts.index("m") ||
            tmp_parts.index("2'") ||
            tmp_parts.index("m'")
      raise "cannot determine unique name if no m or 2 in name" unless idx
      idx += 1
      set_name(species, parts, idx)
    end

    # parts is an array of name parts, idx is the index to insert the symbol at so idx-1
    # is the index of the part we are naming
    def self.set_name(species, parts, idx)
      # Convert it to a symbol
      sym = idx > 0 ? STR_TO_SYM[parts[idx - 1]] : STR_TO_SYM[parts[idx]]

      # Use rule 0 to get a species character for that element (+/|_)
      fingerprint = species.orientation.fingerprint
      has_sym = fingerprint.select { |_, sym_arr| sym_arr.includes?(sym) }
      if species.parent.family == Family::Cubic
        classification = has_sym[AxisKind::OffAxes]? ? AxisKind::OffAxes : AxisKind::OnAxes
      else
        classification = has_sym[AxisKind::Planar]? ? AxisKind::Planar : AxisKind::Axial
      end

      # Stick that in the array at the right spot and save the string of it.
      new_name = parts.insert(idx, classification.symbol).join("")
      species.child_name = new_name
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
