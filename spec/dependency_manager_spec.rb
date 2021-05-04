require 'support/basic_factories'

RSpec.describe DependencyManager do
  it "has a version number" do
    expect(DependencyManager::VERSION).not_to be nil
  end

  xit "does something useful" do
    container = DependencyManager::Container.new(
      app_context: AppContext.new(
        name: 'Test',
        env: 'test'
      ),

      # In other cases this could be loaded from YAML, JSON, or another source
      configuration: {
        logger: {
          # If this is disabled, you'll see this error:
          #   Some dependencies for `TimingFactory` are not present: logger
          #
          # Give it a try!
          enabled: true,
          level: :info
        },

        flags: {
          enabled: true,
          default_values: {
            a: 1,
            b: 2,
            c: 3
          }
        },

        timing: {
          enabled: true
        },

        # Consistently optional dependency, try toggling it
        hype_person: {
          enabled: true
        }
      }
    )

    # Few quick tests
    p fetch: container.fetch(:flags).fetch(:a)
    p set: container.fetch(:flags).set(:a, 3)
    p reset: container.fetch(:flags).reset(:a)
    p state: container.fetch(:flags).state

    expect(true).to eq(true)
  end
end
