require_relative '../support/basic_factories'

RSpec.describe DependencyManager::Container do
  let(:configuration) do
    {
      logger:      { enabled: true, level: :info },
      flags:       { enabled: true, default_values: { a: 1, b: 2, c: 3 } },
      timing:      { enabled: true },
      hype_person: { enabled: true }
    }
  end

  # Normal default, but easier to modify for tests here
  let(:factories) { DependencyManager::Factory.factories }

  subject do
    described_class.new(
      app_context: AppContext.new(name: 'Test', env: 'Test'),
      configuration: configuration,
      factories: factories
    )
  end

  let(:build_result) { subject.build }

  it 'can create a Container' do
    expect(subject).to be_a(described_class)
  end

  context 'When manually constructed rather than using `Factory.factories`' do
    let(:factories) { [LoggerFactory, FlagsFactory, HypePersonFactory] }

    describe '#register' do
      it 'can register a new factory' do
        expect(subject.register(TimingFactory)).to eq([LoggerFactory, FlagsFactory, HypePersonFactory, TimingFactory])
      end

      it 'can build with the newly registered factory' do
        subject.register(TimingFactory)
        expect(build_result).to include({
          logger:      instance_of(Logger),
          flags:       instance_of(Flags),
          timing:      instance_of(Timing),
          hype_person: instance_of(HypePerson)
        })
      end

      context 'When attempting to add a Factory after build' do
        it 'will raise an error' do
          subject.register(TimingFactory)
          build_result

          expect { subject.register(TimingFactory) }.to raise_error(
            DependencyManager::Container::AddedFactoryAfterBuildError,
            "Cannot add Factories after Container has been built"
          )
        end
      end
    end
  end

  describe '#build' do
    it 'can build a dependency chain' do
      expect(build_result).to include({
        logger:      instance_of(Logger),
        flags:       instance_of(Flags),
        timing:      instance_of(Timing),
        hype_person: instance_of(HypePerson)
      })
    end

    context 'When built twice' do
      it 'will raise an error about multiple builds' do
        subject.build
        expect { subject.build }.to raise_error(DependencyManager::Container::BuildOnceError,
          "Cannot build more than once"
        )
      end
    end

    context 'When an optional dependency is disabled' do
      let(:configuration) { super().merge(hype_person: { enabled: false }) }

      it 'will be excluded from the dependency chain' do
        expect(build_result).to include({
          logger: instance_of(Logger),
          flags:  instance_of(Flags),
          timing: instance_of(Timing)
        })

        expect(build_result).to_not include({
          hype_person: instance_of(HypePerson)
        })
      end
    end

    context 'When a required dependency is disabled' do
      let(:configuration) { super().merge(timing: { enabled: false }) }

      it 'will crash the build' do
        expect { build_result }.to raise_error(DependencyManager::Resolver::MissingDependencies,
          "Dependencies for `FlagsFactory` are not present: timing"
        )
      end
    end
  end

  describe '#to_h' do
    it 'returns built dependencies in Hash format' do
      build_result
      expect(subject.to_h).to include({
        logger:      instance_of(Logger),
        flags:       instance_of(Flags),
        timing:      instance_of(Timing),
        hype_person: instance_of(HypePerson)
      })
    end
  end

  describe '#fetch' do
    it 'can fetch a single dependency' do
      build_result
      expect(subject.fetch(:logger)).to be_a(Logger)
    end
  end

  describe '#dependency_tree' do
    it 'returns a dependency tree to build from that can be ordered' do
      dependency_tree = subject.dependency_tree

      expect(dependency_tree).to eq(
        logger_factory:      [],
        flags_factory:       [:logger_factory, :timing_factory, :hype_person_factory],
        timing_factory:      [:logger_factory, :hype_person_factory],
        hype_person_factory: []
      )

      expect(dependency_tree.tsort).to eq([:logger_factory, :hype_person_factory, :timing_factory, :flags_factory])
    end
  end
end
