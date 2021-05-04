require_relative '../support/basic_factories'
require 'pry'

RSpec.describe DependencyManager::Factory do
  let(:logger_config) do
    {
      app_context: double,
      factory_config: { enabled: true, level: :info }
    }
  end

  let(:logger_factory) { LoggerFactory }
  subject { logger_factory.new(logger_config) }

  let(:flags_factory) { FlagsFactory }

  it 'can create a Factory instance' do
    expect(subject).to be_a(described_class)
  end

  describe '#enabled' do
    it 'will show whether or not the factory is enabled' do
      expect(subject.enabled?).to eq(true)
    end

    context 'When turned off' do
      let(:logger_config) do
        {
          app_context: double,
          factory_config: { enabled: false, level: :info }
        }
      end

      it 'will be off' do
        expect(subject.enabled?).to eq(false)
      end
    end
  end

  describe '#build' do
    it 'can build a factory instance' do
      expect(subject.build).to be_a(Logger)
    end

    context 'When a configuration value is invalid' do
      let(:logger_config) do
        {
          app_context: double,
          factory_config: { enabled: true, level: :invalid }
        }
      end

      it 'will raise an error' do
        expect { subject.build }.to raise_error(ArgumentError,
          "Configuration is invalid: [:level] must be one of: warn, danger, info, debug"
        )
      end
    end
  end

  describe '.const_name' do
    it 'returns the constant name of the factory' do
      expect(logger_factory.const_name).to eq("LoggerFactory")
    end
  end

  describe '.name' do
    it 'returns a snake-cased variant of the name' do
      expect(logger_factory.name).to eq(:logger_factory)
    end
  end

  describe '.dependency_name' do
    it 'gets the injected dependency name expected to be tied to the factory' do
      expect(logger_factory.dependency_name).to eq(:logger)
    end
  end

  describe '.parameters' do
    it 'returns the parameters of the initialize method' do
      expect(flags_factory.parameters).to eq([
        [:keyreq, :logger],
        [:keyreq, :timing],
        [:key, :hype_person],
        [:keyrest, :dependencies]
      ])
    end
  end

  describe '.dependencies' do
    it 'lists the dependencies expected of the Factory' do
      expect(flags_factory.dependencies).to eq([:logger, :timing, :hype_person])
    end
  end

  describe '.factory_dependencies' do
    it 'lists the factories needed to create dependencies it needs' do
      expect(flags_factory.factory_dependencies).to eq([:logger_factory, :timing_factory, :hype_person_factory])
    end
  end

  describe '.required_dependencies' do
    it 'lists dependencies required to build the factory' do
      expect(flags_factory.required_dependencies).to eq([:logger, :timing])
    end
  end

  describe '.optional_dependencies' do
    it 'lists dependencies not strictly required to build the factory' do
      expect(flags_factory.optional_dependencies).to eq([:hype_person])
    end
  end

  describe '.factories' do
    it 'lists all child factory classes' do
      expect(described_class.factories).to eq([LoggerFactory, FlagsFactory, TimingFactory, HypePersonFactory])
    end
  end

  describe '.get' do
    it 'gets a factory by snake_cased name' do
      expect(logger_factory.get(:logger_factory)).to eq(LoggerFactory)
    end

    context 'When the factory does not exist' do
      it 'raises an error' do
        expect { logger_factory.get(:invalid_factory) }.to raise_error(ArgumentError,
          "Tried to get non-existant Factory. Did you remember to define it?: InvalidFactory"
        )
      end
    end
  end
end
