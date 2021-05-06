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

It should be noted that there are no particularly quick starts to using this library. It is suggested to read over the entire Overview and Usage. Quick References will be created soon.

## Overview and Usage

DependencyManager uses a few core concepts:

* `DependencyTree` - `TSort`-based system for ordering dependencies by what depends on what.
* `Factory` - Builds dependencies from configuration and validates them.
* `Resolver` - Resolves dependencies needed for each `Factory`.
* `Container` - Builds and stores the artifacts of each finished `Factory`.

Users will only directly interact with the `Factory` and the `Container`, while `DependencyTree` and `Resolver` will help wire everything together behind the scenes. We'll be focusing on the two public interfaces.

### Factories

A `Factory` seeks to fulfill a few goals:

* **Filtering** - A `Factory` may be disabled, causing it to not build.
* **Configure** - Defines and extracts configuration for dependencies.
* **Validate** - Validates that configuration using `Dry::Schema`.
* **Loading** - Loads external dependencies like gems via `require`.
* **Dependency Chains** - Finds dependencies necessary to "build" a factory.
* **Build** - Builds the dependency based on the above content.

#### Factory Filtering

Factories can be enabled or disabled through the `enabled?` method, which defaults to `false` in the `Factory` class which children inherit from:

```ruby
class MyFactory < DependencyManager::Factory
  # ...

  def enabled?
    configuration[:enabled] == true
  end

  # ...
end
```

Just defining this method, however, will not do much unless you remember to put it in your build step:

```ruby
class MyFactory < DependencyManager::Factory
  # ...

  def build
    return unless enabled?

    # ...
  end

  def enabled?
    configuration[:enabled] == true
  end

  # ...
end
```

...which will cause it to not be injected into downstream `Factory` builds.

#### Factory Configuration

Factories are configured via an injected `Hash` from the `Container`, and a user determined `app_context`:

```ruby
# /lib/dependency_manager/factory.rb
def initialize(app_context: nil, factory_config:)
  @app_context = app_context
  @factory_config = factory_config
end
```

The application context is typically a class containing information like environment, name, and other meta-information. This is defaulted to `nil` to represent an optional dependency.

The `factory_config` is derived from the name of the `Factory`:

```ruby
# /lib/dependency_manager/container.rb
private def get_config(klass)
  @configuration.fetch(klass.dependency_name, {})
end
```

...which is automatically provided from the `Factory`s class name. For instance, `LoggerFactory` would have a dependency name of `logger`, and would feed the `logger` values from the following configuration passed to a container:

```ruby
# /spec/dependency_manager/container_spec.rb
{
  logger:      { enabled: true, level: :info },
  flags:       { enabled: true, default_values: { a: 1, b: 2, c: 3 } },
  timing:      { enabled: true },
  hype_person: { enabled: true }
}
```

In your own `Factory`s there are two configuration methods to keep in mind: `configuration` and `default_configuration`:

```ruby
# Inline definition

# Config stanza:
#   { a: 3, b: 4 }

class MyFactory < DependencyManager::Factory
  # Depends on logger, forwards `app_context` and `configuration` on to the parent class
  def initialize(logger:, **dependencies)
    super(**dependencies)
    @logger = logger
  end

  # Would return: { a: 3, b: 4, c: 3 }
  def configuration
    # Default implementation, use `super()` here to get this config
    # if you want to do more configuration. Caching is used by default as well.
    @configuration ||= deep_merge(default_configuration, @factory_config)
  end

  # Reasonable defaults for the class, defaulting to `{}` unless specified
  def default_configuration
    { a: 1, b: 2, c: 3 }
  end
end
```

Configurations are typically used in the build phase of a `Factory`.

As with other methods it's not necessary unless you need it, and `build` will not automiatically call it.

#### Factory Validation

An optional, but recommended step, to validate configurations:

```ruby
# /spec/support/dependency_factories/flags_factory.rb
class FlagsFactory < DependencyManager::Factory
  validate_with do
    required(:enabled).filled(:bool)
    required(:default_values).hash
  end

  # ...
end
```

This will validate `configuration` by using [`Dry::Schema`](https://dry-rb.org/gems/dry-validation/1.6/) validations via the `validate!` (error raising) and `validate` (result returning) methods.

It's recommended to run this in the `build` step of your `Factory` right after checking if it's enabled:

```ruby
# /spec/support/dependency_factories/flags_factory.rb
class FlagsFactory < DependencyManager::Factory
  validate_with do
    required(:enabled).filled(:bool)
    required(:default_values).hash
  end

  # ...

  def build
    return unless enabled?

    validate!

    # ...
  end

  # ...
end
```

As with other methods it's not necessary unless you need it, and `build` will not automiatically call it.

#### Factory Loading

Some `Factory`s, if not most, are created to load gems that you don't own into your Service Container ecosystem. `load_requirements` is how `DependencyManager` handles that issue:

```ruby
# /spec/support/dependency_factories/flags_factory.rb
class FlagsFactory < DependencyManager::Factory
  # ...

  def build
    return unless enabled?

    validate!

    load_dependencies

    # ...
  end

  def load_dependencies
    require 'flags'
  end

  # ...
end
```

As with other methods it's not necessary unless you need it, and `build` will not automiatically call it.

#### Factory Dependency Chains

Dependency chains are the main reason this library exists. In a Service Container dependencies rely on each other, often times in hard to manage orders. `DependencyManager` solves this using the arguments to the `initialize` function on each `Factory` to find dependencies:

```ruby
def initialize(logger:, other:, optional: nil)
```

In this case there are required dependencies on `:logger` and `:other`, but an optional dependency on `:optional`. These work via required kwargs and optional kwargs, and `nil` isn't the only value that can be used there, in fact more sane defaults are a better idea where possible.

These names correspond to, and require the presence of factories named `LoggerFactory`, `OtherFactory`, and `OptionalFactory`. Without them the program will crash and warn you of this:

```ruby
# spec/dependency_manager/factory_spec.rb > .get > When the factory does not exist
"Tried to get non-existant Factory. Did you remember to define it?: InvalidFactory"
```

Missing resources in general will attempt to raise informative errors to let you know what might have gone wrong.

#### Factory Builds

The final step of a factory is to actually build it and get the dependency back out the other side, and all together it'll look a bit something like this:

```ruby
# /spec/dependency_manager/container_spec.rb
#
# Flag configuration stanza:
{ enabled: true, default_values: { a: 1, b: 2, c: 3 } },

# /spec/support/dependency_factories/flags_factory.rb
class FlagsFactory < DependencyManager::Factory
  validate_with do
    required(:enabled).filled(:bool)
    required(:default_values).hash
  end

  def initialize(logger:, timing:, hype_person: nil, **dependencies)
    super(**dependencies)

    @logger = logger
    @timing = timing
    @hype_person = hype_person
  end

  def build
    return unless enabled?

    validate!

    load_requirements

    Flags.new(
      logger: @logger,
      timing: @timing,
      default_values: configuration[:default_values],
      hype_person: @hype_person
    )
  end

  def load_requirements
    require 'flags'
  end

  def enabled?
    configuration[:enabled] == true
  end
end
```

In general the order for a `build` function should be:

* Is it on?
* Is it valid?
* What do we need to load to make it work?
* Get configuration ready
* Build it!

This factory has no `configuration` step defined, but uses the automatically built `configuration` to get `:default_values`.

Once built by the `Container` it will be registered and fed to other dependencies executing later that require what it produces, which brings us to `Container` next.

### Containers

A `Container` is what brings all the `Factory`s together to produce the dependencies you need to run your application.

It aims to do a few things:

* **Capture Configuration** - `Container` takes pre-read configuration in the format `Hash[Symbol, Any]`
* **Load Factories** - Load all the `Factory`s
* **Load Dependency Tree** - Call out to `DependencyTree` and find out what needs to be built
* **Order Dependencies** - Based on dependencies, use `tsort` to order dependencies from `DependencyTree`.
* **Resolve Dependencies** - Resolve requirements from `Factory` based on what's already been built, if any are required.
* **Build Factory** - Build the `Factory` and wire it back into dependencies for downstream `Factory`s to potentially use.
* **Present Dependencies** - Once they're done, give back dependencies to use how you see fit.

#### Container Configuration

`Container` will not load configuration, but instead takes it directly in the form of a `Hash[Symbol, Any]`:

```ruby
# Modified from: /spec/dependency_manager/container_spec.rb

AppContext = Struct.new(:name, :env)

container = DependencyManager::Container.new(
  app_context:   AppContext.new('README', 'test'),
  configuration: {
    logger:      { enabled: true, level: :info },
    flags:       { enabled: true, default_values: { a: 1, b: 2, c: 3 } },
    timing:      { enabled: true },
    hype_person: { enabled: true }
  },
  factories: DependencyManager::Factory.factories
)

container.build

container.fetch(:logger)
# => instance_of Logger
```

Typically this would come from a `YAML` or `JSON` file, but can be manually entered as well.

An `AppContext` can be any class, but is typically useful for changing behavior based on application-level configuration like what environment the script is currently running on and using different configs if it's in sandbox vs production. This option is not necessary, but recommended for more complicated applications.

#### Container Loading Factories

The `factories` option for creating a new `Container` defaults to `Factory.factories`, which contains all classes inheriting from `DependencyManager::Factory`. If this behavior is not wanted an `Array` of `Factory`s can be passed in instead:

```ruby
# Modified from: /spec/dependency_manager/container_spec.rb
factories: DependencyManager::Factory.factories

# ...or manually
factories: [LoggerFactory, FlagsFactory, HypePersonFactory]
```

When using the manual route one can also use `register` to add a new `Factory` before the `Container` is built:

```ruby
container = DependencyManager::Container.new(...)
container.register(HypePersonFactory)
```

...but as this uses a `Set` behind the scenes it will not allow a `Factory` to be loaded more than once.

#### Container Loading Dependency Tree

`Container` uses `DependencyTree` to figure out what depends on what. Using a basic example:

```ruby
# /spec/dependency_manager/dependency_tree_spec.rb
tree = DependencyManager::DependencyTree.new(
  a: [:b, :c],
  b: [:c],
  c: []
)
```

`a` depends on `b` and `c`, `b` depends on `c`, and `c` depends on nothing. Remembering back above, `Factory`s implement a method for finding what other `Factory`s they depend on using the arguments to `initialize` via `factory_dependencies`:

```ruby
# /lib/dependency_manager/factory.rb > Singleton methods

def parameters
  instance_method(:initialize).parameters
end

def dependencies
  dependencies = parameters
    .select { |type, _name| KEYWORD_ARGS.include?(type) }
    .map(&:last)

  dependencies - CONTEXT_DEPENDENCIES
end

def factory_dependencies
  dependencies.map { |d| "#{d}_factory".to_sym }
end
```

So our above hypothetical `initialize` method:

```ruby
def initialize(logger:, other:, optional: nil)
```

...would give us the following dependency chain:

```ruby
[:logger_factory, :other_factory, :optional_factory]
```

It also has additional methods of `required_dependencies` and `optional_dependencies` to figude out what's actually needed to build it successfully. All of this comes for free based on arguments to `initialize` of each `Factory`.

#### Container Ordering Dependencies

Given these `TSort`, which is included in `DependencyTree`, can figure out what order to load dependencies in. Taking a look at our above:

```ruby
# /spec/dependency_manager/dependency_tree_spec.rb
tree = DependencyManager::DependencyTree.new(
  a: [:b, :c],
  b: [:c],
  c: []
)

tree.tsort
# => [:c, :b, :a]
```

It would run `c` then `b` then `a`, which makes sense as `c` has no other dependencies.

`TSort` is also kind enough to keep us from creating cycles by accident:

```ruby
# /spec/dependency_manager/dependency_tree_spec.rb
tree = DependencyManager::DependencyTree.new(
  a: [:b, :c],
  b: [:c],
  c: [:b] # LOOP
)

tree.tsort
# raises TSort::Cyclic
```

#### Container Resolving Dependencies

```ruby
# /lib/dependency_manager/container.rb
resolved_dependencies = Resolver.new(
  factory: factory,
  loaded_dependencies: dependencies
).resolve
```

As each dependency is built it will look into the already built dependencies for dependencies it needs. If `c` is built first, `dependencies` will already have a reference to it for `b` when it comes up to be built, and so forth for `a`.

`/spec/dependency_manager/resolver_spec.rb` contains examples of this behavior, but for now know that it relies on order to cascade dependencies where they need to go when they need to be there.

#### Container Building Dependencies

Once we have the dependencies we can inject hte rest of the information we need, and we now have a factory ready to be built:

```ruby
# /lib/dependency_manager/container.rb
factory_instance = factory.new(
  app_context:    @app_context,
  factory_config: get_config(factory),
  **resolved_dependencies
)
```

...once ready we turn around and build it:

```ruby
# /lib/dependency_manager/container.rb
@dependencies[factory.dependency_name] = factory_instance.build
```

`Factory`s have `dependency_name` which gives back a snake-cased version of just the dependency name, such that `LoggerFactory` becomes `logger`, which is what other `Factory`s expect. We map that name to the produced artifact, and that artifact is now available to all `Factory`s that build after it.

This is the reason for `TSort` is to figure out what that order is. Note this may not be necessary in cases where your dependencies do not have to be actively loaded, and something like `Dry::Container` may be a better idea in those cases.

#### Container Presenting Dependencies

Once that's done all of the dependencies have been created and you can get them out in a few ways:

```ruby
# Modified from: /spec/dependency_manager/container_spec.rb

AppContext = Struct.new(:name, :env)

container = DependencyManager::Container.new(
  app_context:   AppContext.new('README', 'test'),
  configuration: {
    logger:      { enabled: true, level: :info },
    flags:       { enabled: true, default_values: { a: 1, b: 2, c: 3 } },
    timing:      { enabled: true },
    hype_person: { enabled: true }
  },
  factories: DependencyManager::Factory.factories
)

container.build
# All dependencies returned here too, but prefer to use the next two methods

container.fetch(:logger)
# => instance_of Logger

container.to_h
# {
#   logger:      instance_of Logger,
#   flags:       instance_of Flags,
#   timing:      instance_of Timing,
#   hype_person: instance_of HypePerson
# }
```

...and with that you now have a `Container` to work with, whether that be tying into Rails or whatever other framework you're needing to.

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
