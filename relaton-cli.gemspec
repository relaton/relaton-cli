lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "relaton/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "relaton-cli"
  spec.version       = Relaton::Cli::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Relaton Command-line Interface"
  spec.description   = "Relaton Command-line Interface"
  spec.homepage      = "https://github.com/metanorma/relaton-cli"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|docs)/})
  end
  spec.extra_rdoc_files = %w[docs/README.adoc LICENSE]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.0.0"

  spec.add_runtime_dependency "liquid", "~> 5"
  spec.add_runtime_dependency "relaton", "~> 1.20.0"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "thor-hollaback"
end
