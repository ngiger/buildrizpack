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

module BuildrIzPack

  class IzPackTask < Buildr::ArchiveTask

    attr_accessor :control, :prerm, :postinst, :postrm, :preinst, :triggers, :version

    # The ArchiveTask class delegates this method
    # so we can create the archive.
    # the file_map is the result of the computations of the include and exclude filters.
    # 
    # With deb we recreate the structure asked by the user
    # then we will call dpkg --build over it.
    def create_from(file_map)  
      root = File.join("target", "#{File.basename(name)}-contents")
      mkpath File.join(root, "DEBIAN")
      for filename in ["control", "prerm", "postinst", "postrm", "preinst", "triggers"]
        file = send(filename)
        if file.nil?
          raise "no control file was defined when packaging as a deb file" if filename == "control"
        else
          raise "Cannot find #{filename}: #{file} doesn't exist" if !File.exists? file
          target = File.join(root, "DEBIAN", filename)
          contents = File.read(file)
          # Replace version and use ERB to evaluate the control file, in case there are variables to pass.
          if (filename == "control" && !@version.nil?)
            contents.gsub!(/^Version: .*$/, "Version: #{@version}") 
            File.open(target, "w") {|t|
              t.write ERB.new(contents).result
            }
          else
            cp file.to_s, target
          end
          
          File.chmod 0755, target
        end
      end
      file_map.each do |path, content|
        _path = File.join(root, path)
        if content.respond_to?(:call)
          raise "Not implemented"
          #content.call path
        elsif content.nil?
          mkdir_p _path
        elsif File.directory?(content.to_s)
          
        else
          mkdir_p File.dirname(_path) if !File.exists?(File.dirname(_path))
          cp content.to_s, _path
        end
      end
      out = %x[ dpkg --build \"#{root}\" \"#{name}\" 2>&1 ]
      raise "dpkg failed with this error:\n#{out}" if $? != 0
    end

  end

  module ActAsIzPackPackager
    include Extension

    def package_as_deb(file_name)
      deb = IzPackTask.define_task(file_name)
      deb.enhance do |task|
        task.enhance do
          package ||= project.id
          version ||= project.version
        end
      end
      return deb
    end
  end
end

module Buildr
  class Project
    include BuildrIzPack::ActAsIzPackPackager
  end
end