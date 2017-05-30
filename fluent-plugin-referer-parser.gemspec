# -*- encoding: utf-8 -*-
require 'English'

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-referer-parser'
  gem.version       = '0.0.9'
  gem.authors       = ['TAGOMORI Satoshi', 'HARUYAMA Seigo']
  gem.email         = ['haruyama@unixuser.org']
  gem.description   = %q(parsing by referer-parser. See: https://github.com/snowplow/referer-parser)
  gem.summary       = %q(Fluentd plugin to parse UserAgent strings)
  gem.homepage      = 'https://github.com/haruyama/fluent-plugin-referer-parser'
  gem.license       = 'Apache-2.0'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/\Abin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/\A(test|spec|features)\//)
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit', '>= 3.2'
  gem.add_runtime_dependency 'fluentd', '~> 0.12.0'
  gem.add_runtime_dependency 'referer-parser', '~> 0.3.0'
end
