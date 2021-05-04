# DependencyManager

Dependency Manager using Dependency Injection wire together dependencies into a Service Container.

This tool may be unnecessary for dependency chains with only a few dependencies, but if you find yourself dealing with 20 or more dependencies you need to wire together this will quickly become very useful.

Dependency Manager uses Factories to assemble dependencies, and uses the arguments of `initialize` to figure out what depends on what, and finally what order all the dependencies should be loaded in.

Consider this example factory:

```ruby
class FlagsFactory < DependencyManager::Factory
  # ...

  def initialize(logger:, timing:, hype_person: nil, **dependencies)
    super(**dependencies)

    @logger = logger
    @timing = timing
    @hype_person = hype_person
  end

  # ...
end
```

This factory would depend on a `LoggerFactory` and `TimingFactory`, and have an optional dependency on a `HypePerson` factory. The remaining `**dependencies` relate to the base `DependencyManager` factory which we'll get into in a moment.

## Usage

TODO: Write usage instructions here:

1. Overview usage
2. Base factory
3. Creating new factories
4. Validating configurations
5. Come up with more list items

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dependency_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dependency_manager

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/baweaver/dependency_manager. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DependencyManager project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/dependency_manager/blob/master/CODE_OF_CONDUCT.md).
