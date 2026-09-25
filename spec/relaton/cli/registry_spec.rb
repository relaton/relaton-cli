# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Relaton::Cli.registry" do
  it "resolves the processor registry on either relaton line" do
    registry = Relaton::Cli.registry
    expect(registry).to respond_to(:by_type)
    expect(registry).to respond_to(:processors)
  end

  it "routes a type to a processor without raising" do
    expect { Relaton::Cli.registry.by_type("ISO") }.not_to raise_error
  end
end
