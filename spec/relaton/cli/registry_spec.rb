# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Relaton::Cli.registry" do
  it "resolves the relaton v3 processor registry" do
    expect(Relaton::Cli.registry).to be(Relaton::Db::Registry.instance)
  end

  it "routes a type to a processor without raising" do
    expect { Relaton::Cli.registry.by_type("ISO") }.not_to raise_error
  end
end
