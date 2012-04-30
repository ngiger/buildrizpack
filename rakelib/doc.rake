# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

gem 'rdoc'
require 'rdoc/task'
desc "Creates a symlink to rake's lib directory to support combined rdoc generation"
file "rake/lib" do
  rake_path = $LOAD_PATH.find { |p| File.exist? File.join(p, "rake.rb") }
  mkdir_p "rake"
  File.symlink(rake_path, "rake/lib")
end

desc "Generate RDoc documentation in rdoc/"
RDoc::Task.new :rdoc do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = spec.name
  rdoc.options = spec.rdoc_options.clone
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include spec.extra_rdoc_files

  # include rake source for better inheritance rdoc
  rdoc.rdoc_files.include('rake/lib/**.rb')
end
task :rdoc => ["rake/lib"]

if `pygmentize -V`.empty?
  puts "Buildr uses the Pygments python library. You can install it by running 'sudo easy_install Pygments'"
end


task :clobber do
  rm_rf 'rdoc'
end
