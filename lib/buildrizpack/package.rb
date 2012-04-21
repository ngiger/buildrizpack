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

require "rexml/document"
include REXML

module BuildrIzPack

  class IzPackTask < Buildr::ArchiveTask
    # The version of IzPack to use. Defaults to 4.3.5
    IZPACK_VERSION = '4.3.5'
    
    # a hash of name => value to be passed when calling the izpack installer
    # See also IzPackTask.html[http://www.jarvana.com/jarvana/view/org/codehaus/izpack/izpack-standalone-compiler/4.0.1/izpack-standalone-compiler-4.0.1-javadoc.jar!/com/izforge/izpack/ant/IzPackTask.html]
    attr_accessor :properties
    # "IzPack"[http://izpack.org/documentation/installation-files.html] to be used as starting point for calling the izpack installer
    # some or all of its content may be overwritten, if you specify other attributes, e.g.
    # if you want to specify one or mor pack bundles with a file list maintained by buildr.
    # If not specified BuildrIzPack will create one at File.join(project.path_to(:target, 'install.xml'))
    attr_accessor :input
    # ther version of the izpack installer to be used. Defaults to IZPACK_VERSION
    attr_accessor :izpackVersion
    # Application name used by the IzPack installer. Defaults to the current project
    attr_accessor :appName
    # The installer output directory and filename (defaults to <project>-<version>.izpack)
    attr_accessor :output
    # The base directory of compilation process (defaults project.path_to(:target))
    attr_accessor :basedir
    # The installer type (defaults to standard). You can select between standard and web.
    attr_accessor :installerType
    # It seems that in order to propagate all project properties to the the izpack compiler you need to set the inheritAll attribute to "true".
    # Therefore it defaults to true
    attr_accessor :inheritAll
    # defaults to deflate. You can select between default, deflate and raw.
    attr_accessor :compression
    # defaults to 9. The compression level of the installation (defaults to -1 for no compression). Valid values are -1 to 9.
    attr_accessor :compressionLevel
    # defaults to package(:jar). The jars for the main pack
    attr_accessor :jars

    # The ArchiveTask class delegates this method
    # so we can create the archive.
    # the file_map is the result of the computations of the include and exclude filters.
    # 
    def create_from(file_map)
      @izpackVersion ||= IZPACK_VERSION 
      @appName ||= project.id
      @izpackBaseDir = File.dirname(@output) if !@izpackBaseDir
      @installerType ||= 'standard'
      @inheritAll ||= 'true'
      @compression ||= 'deflate'
      @compressionLevel ||= '9'
      p 5 
      raise "You must include at least one file to create an izPack installer" if file_map.size == 0
      p @jars
      p file_map
      @jars ||= [ package(:jar).to_s ]
      izPackArtifact = Buildr.artifact( "org.codehaus.izpack:izpack-standalone-compiler:jar:#{@izpackVersion}")
      p "create from #{file_map.inspect} using #{izPackArtifact.to_s}"
      p "create with jars  #{@jars.inspect}"
      file_map.each do |path, content|
	p 4
	p path
	p content
	p root
        _path = File.join(root, path)
        if content.respond_to?(:call)
          raise "Not implemented"
          #content.call path
        elsif content.nil?
          mkdir_p _path
        elsif File.directory?(content.to_s)
          p 8888
        else
          mkdir_p File.dirname(_path) if !File.exists?(File.dirname(_path))
          cp content.to_s, _path
        end
      end
      p "68: #{@input} #{File.exists?(@input)}"
      doc = nil
      if !File.exists?(@input)
	# Then we generate a default, very basic installer
	doc = Document.new
	doc << XMLDecl.new
        doc.add_element('installation').add_element('info').add_element('appname').text = @appName
	doc.elements['installation'].attributes['version'] = '1.0'
	doc.elements['installation/info'].add_element('appversion').text = @version
	doc.elements['installation'].add_element('locale').add_element('langpack').attributes['iso3'] = 'eng'
	doc.elements['installation'].add_element('panels').add_element('panel').attributes['classname'] = 'InstallPanel'
	doc.elements['installation'].add_element('packs').add_element('pack').attributes['name'] = 'main'
	doc.elements['installation/packs/pack'].add_element('description').text = "A dummy description for #{@appName}"
	doc.elements['installation/packs/pack'].attributes['required'] = 'yes'
	@jars.each{ 
	  |aJar|
	  doc.elements['installation/packs/pack'].add_element('file').attributes['targetdir']="$SYSTEM_user_home/#{@appName}"
	  doc.elements['installation/packs/pack/file'].attributes['src']=aJar
	}
	doc.write(File.open(@input, 'w+'), 2)
	# doc.write($stdout, 2)
      else
	p 71
	doc = Document.new File.new(@input)
      end
      shouldBe = %(
      <installation version="1.0">
	<info>
		<appname>demo app</appname>
		<appversion>7.6.5</appversion>
	</info>
	<locale>
		<langpack iso3="eng" />
	</locale>
	<panels>
		<panel classname="InstallPanel" />
	</panels>
	<packs>
		<pack name="Demo-App" required="yes">
			<description>Our demo app.</description>
			<file src="withXml-1.0.0.001.jar" targetdir="$SYSTEM_user_home/demo" />
		</pack>
	</packs>
</installation>)    
      p @izpackBaseDir
      p @output
      Buildr.ant('izpack-ant') do |x|
	izPackArtifact.invoke
	msg = "Generating izpack aus #{File.expand_path(@input)} #{File.exists?(File.expand_path(@input))}"
	p msg
	if properties
	  properties.each{ |name, value|
			    puts "Need added property #{name} with value #{value}"
			  x.property(:name => name, :value => value) 
			}
	end
	x.echo(:message =>msg)
	x.taskdef :name=>'izpack', 
	  :classname=>'com.izforge.izpack.ant.IzPackTask', 
	  :classpath=>izPackArtifact.to_s
	x.izpack :input=> @input,
		  :output => @output,
		  :basedir => @izpackBaseDir,
		  :installerType=> @installerType,
		  :inheritAll=> @inheritAll,
		  :compression => @compression,
		  :compressionLevel => @compressionLevel do
	end
      end
    end

  end
was= %(
    module ActAsDebPackager
    include Extension

    def package_as_deb(file_name)
      deb = DebTask.define_task(file_name)
      deb.enhance do |task|
        task.enhance do
          package ||= project.id
          version ||= project.version
        end
      end
      return deb
    end
  end
)
  module ActAsIzPackPackager
    include Extension

    def package_as_izpack(file_name)
      izpack = IzPackTask.define_task(file_name)
      izpack.enhance do |task|
	task.jars ||= [ package(:jar).to_s ]
        task.enhance do
          package ||= project.id
          version ||= project.version
        end
	task.input ||= File.join(project.path_to(:target, 'install.xml'))
	task.appName ||= project.id
	task.output ||=  file_name
	task.basedir ||= project.path_to(:target)
	task.installerType ||= 'standard'
	task.inheritAll ||= 'true'
	task.compression ||= 'deflate'
	task.compressionLevel ||= '9'
      end
      return izpack
    end
  end
end

module Buildr
  class Project
    include BuildrIzPack::ActAsIzPackPackager
  end
end