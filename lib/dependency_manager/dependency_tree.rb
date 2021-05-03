require 'tsort'
require 'delegate'

module DependencyManager
  # Dependency tree implementation using TSort to resolve the order in which
  # factories should be run.
  class DependencyTree < Delegator
    include TSort

    attr_reader :resources

    # Allow access to the underlying hash
    alias_method :__getobj__, :resources

    def initialize(resources)
      @resources = resources
    end

    # TSort interface method
    def tsort_each_node(&block)
      @resources.each_key(&block)
    end

    # TSort interface method
    def tsort_each_child(node, &block)
      @resources.fetch(node).each(&block)
    end
  end
end
