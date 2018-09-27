# SymmSpecies

`SymmSpecies` is a [Crystal](https://crystal-lang.org/) library for working with the 212 non-magnetic [Aizu species](https://journals.aps.org/prb/abstract/10.1103/PhysRevB.2.754). i.e. we are interested in the specific, symmetrically distinct, orientations of the crystallographic point groups (see [Symm32](https://gitlab.com/crystal-symmetry/symm32)) "within" one another.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  symm_species:
    gitlab: gitlab/symm_species
```

## Usage

```crystal
require "symm_species"
```

Your application will now have available to it the array `SymmSpecies::LIST` and the helper methods `SymmSpecies.number(num)` to get a species by number and `SymmSpecies.species_for(parent)` for accessing the species where the point group `parent` is a parent.

Examples of Crystal applications that use this shard:

* [Limit Groups](https://gitlab.com/crystal-symmetry/limit_groups)
* [Hasse](https://gitlab.com/crystal-symmetry/hasse)

For further documentation, please see [the docs](https://crystal-symmetry.gitlab.io/symm_species).

## Contributing

Contributions are welcome! To get things started you can [open an issue](https://gitlab.com/crystal-symmetry/symm_species/issues/new) and post a comment, correction, or feature request. From there we can talk about how best to incorporate (or not) your feedback.

Please note! Your contribution should include tests and be well documented. If you're new to crystal then you might want to at least read this section of the docs: [Writing Shards](https://crystal-lang.org/docs/guides/writing_shards.html).

In general, if you want, you can just pull this code down, start hacking on it, and then push it back here as a "Pull Request", then we can discuss your proposed changes.

1. Fork it (<https://gitlab.com/crystal-symmetry/symm_base/forks/new>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

But I recommend you start off by opening an issue so that you don't waste time on a potentially unwelcome change.

## Contributors

- [KCErb](https://gitlab.com/KCErb) KC Erb - creator, maintainer
