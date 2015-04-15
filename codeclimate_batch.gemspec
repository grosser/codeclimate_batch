name = "codeclimate_batch"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, CodeclimateBatch::VERSION do |s|
  s.summary = "Report a batch of codeclimate results by merging and from multiple servers"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.add_runtime_dependency "json"
  s.executables = ["codeclimate-batch"]
end
