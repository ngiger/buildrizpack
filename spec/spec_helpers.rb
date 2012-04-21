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

unless defined?(SpecHelpers)
  module SandboxHook

    def SandboxHook.included(spec_helpers)
      # For testing we use the gem requirements specified on the buildr4osgi.gemspec
      spec = Gem::Specification.load(File.expand_path('../buildrizpack.gemspec', File.dirname(__FILE__)))
      spec.dependencies.each { |dep| gem dep.name, dep.requirement.to_s }
      # Make sure to load from these paths first, we don't want to load any
      # code from Gem library.
      $LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
      require 'buildrizpack'
    end
  end
  require File.join(File.dirname(__FILE__), "/../buildr/spec/spec_helpers.rb")

end
