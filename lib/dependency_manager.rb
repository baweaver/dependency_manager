require "dependency_manager/version"

require "dependency_manager/container"
require "dependency_manager/dependency_tree"
require "dependency_manager/factory"
require "dependency_manager/resolver"

module DependencyManager
  class Error < StandardError; end

  # Produces a dependency map from all factories and their associated
  # dependencies.
  #
  # @return [DependencyManager::DependencyTree]
  def self.dependency_map
    factory_classes = Factory.factories

    DependencyTree.new factory_classes
      .map { |k| [k.name, k.factory_dependencies] }
      .to_h
  end
end
