require_relative '../support/basic_factories'

RSpec.describe DependencyManager::Resolver do
  let(:logger) { double }
  let(:timing) { double }

  let(:target_factory) { FlagsFactory }
  let(:loaded_dependencies) { { logger: logger, timing: timing } }

  subject do
    described_class.new(
      factory: target_factory,
      loaded_dependencies: loaded_dependencies
    )
  end

  it 'can create a Resolver' do
    expect(subject).to be_a(described_class)
  end

  describe '#resolve' do
    it 'can resolve dependencies' do
      expect(subject.resolve).to eq({ logger: logger, timing: timing })
    end

    context 'When irrelevant dependencies are present' do
      let(:loaded_dependencies) { super().merge(a: nil, b: nil, c: nil) }

      it 'will only load what is needed' do
        expect(subject.resolve.keys).to eq([:logger, :timing])
      end
    end

    context 'When a dependency is missing' do
      let(:loaded_dependencies) { { logger: logger } }

      it 'will fail and warn the user of missing dependencies' do
        error = "Dependencies for `FlagsFactory` are not present: timing"
        expect { subject.resolve }.to raise_error(ArgumentError, error)
      end
    end
  end
end
