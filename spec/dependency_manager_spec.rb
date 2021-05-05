require 'support/basic_factories'

RSpec.describe DependencyManager do
  it "has a version number" do
    expect(DependencyManager::VERSION).not_to be nil
  end
end
