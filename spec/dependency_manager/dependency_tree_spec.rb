require_relative '../support/basic_factories'

RSpec.describe DependencyManager::DependencyTree do
  let(:mapping) do
    {
      a: [:b, :c],
      b: [:c],
      c: []
    }
  end

  subject { described_class.new(mapping) }

  it 'can create a DependencyTree' do
    expect(subject).to be_a(described_class)
  end

  it 'delegates to the underlying Hash' do
    expect(subject.to_h).to eq(mapping)
  end

  describe '#tsort' do
    it 'topologically sorts dependencies via TSort' do
      expect(subject.tsort).to eq([:c, :b, :a])
    end

    context 'When a loop exists' do
      let(:mapping) { super().merge(c: [:b]) }

      it 'will raise a cyclical error' do
        expect { subject.tsort }.to raise_error(TSort::Cyclic)
      end
    end
  end
end
