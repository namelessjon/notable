require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.libs << 'lib'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = false
end

task :default => :spec
