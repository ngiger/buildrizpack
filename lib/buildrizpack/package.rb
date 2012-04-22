# encoding: UTF-8

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
    
    # a hash of name => value to be passed when calling the izpack installer
    # See also IzPackTask.html[http://www.jarvana.com/jarvana/view/org/codehaus/izpack/izpack-standalone-compiler/4.0.1/izpack-standalone-compiler-4.0.1-javadoc.jar!/com/izforge/izpack/ant/IzPackTask.html]
    attr_accessor :properties
    # "IzPack"[http://izpack.org/documentation/installation-files.html] to be used as starting point for calling the izpack installer
    # some or all of its content may be overwritten, if you specify other attributes, e.g.
    # if you want to specify one or mor pack bundles with a file list maintained by buildr.
    # If not specified BuildrIzPack will create one at File.join(project.path_to(:target, 'install.xml'))
    attr_accessor :input
    # ther version of the izpack installer to be used. Defaults to 4.3.5
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
    # the packs  (including attributes, fileset, os-dependencies etc). Must be an array of XmlMarkup object.
    attr_accessor :packs
    
    # The supported locale's for the installer. Must be an array of XmlMarkup object. Defaults to ['eng']
    # For details look at IzPacks installation.dtd (Distributed with this gem)
    attr_accessor :locales
    # IzPacks panels's. Must be an array of XmlMarkup object. Defaults to ['TargetPanel', 'InstallPack']
    attr_accessor :panels
    # the supported locale's. Must be an array of XmlMarkup object. Defaults to 680 x 520
    attr_accessor :guiprefs
    
    attr_accessor :packaging, :properties, :variables, :dynamicvariables, :conditions, :installerrequirements,:resources,
                        :listeners, :jar, :native

    # The ArchiveTask class delegates this method
    # so we can create the archive.
    # the file_map is the result of the computations of the include and exclude filters.
    # 
    def create_from(file_map)
      @izpackVersion ||= '4.3.5' 
      @appName ||= project.id
      @izpackBaseDir = File.dirname(@output) if !@izpackBaseDir
      @installerType ||= 'standard'
      @inheritAll ||= 'true'
      @compression ||= 'deflate'
      @compressionLevel ||= '9'
      @locales ||= ['eng']
      @panels  ||= ['TargetPanel', 'InstallPanel']
      @packs   ||= 
      raise "You must include at least one file to create an izPack installer" if file_map.size == 0 and !File.exists?(@input)
      izPackArtifact = Buildr.artifact( "org.codehaus.izpack:izpack-standalone-compiler:jar:#{@izpackVersion}")
      doc = nil
      if !File.exists?(@input)
	genInstaller(Builder::XmlMarkup.new(:target=>File.open(@input, 'w+'), :indent => 2), file_map)
	# genInstaller(Builder::XmlMarkup.new(:target=>$stdout, :indent => 2), file_map)
	# genInstaller(Builder::XmlMarkup.new(:target=>File.open('/home/niklaus/tmp2.xml', 'w+'), :indent => 2), file_map)
      end
      Buildr.ant('izpack-ant') do |x|
	izPackArtifact.invoke
	msg = "Generating izpack aus #{File.expand_path(@input)} #{File.size(@input)}"
	trace msg
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
    
  private 
    def genInstaller(xm, file_map)
      xm.instruct!
      xm.installation('version'=>'1.0') {
	xm.tag!('info') { xm.appname(@appName); xm.appversion(@version)}
	if @guiprefs then xm << @guiprefs
	else
	  xm.guiprefs('width' => '680', 'height' => '520', 'resizable' => 'yes')
	end
	if @panels.class == String then xm << @panels
	else
	  xm.panels { 
	    @panels.each{ |x| xm.panel('classname' => x) }
	  }
	end
	if @panels.class == String then xm << @panels
	else
	  xm.locale { 
	    @locales.each{ |x| xm.langpack('iso3'=>x) }
	  }
	end
	if @packs then xm << @packs
	else
	  #default definiton of packs
	  xm.packs {
	  xm.pack('name' => 'main', 'required' => 'yes') {
							  xm.description("Main pack of #{@appName}")
	    file_map.each{ |src,aJar|
			xm.file('src'=> aJar, 'targetdir' =>'$INSTALL_PATH')
	      }
	    }
	  }
	end
	[@packaging, @properties, @variables, @dynamicvariables, @conditions, @installerrequirements,@resources,@listeners, @jar, @native].each do
	  |element|
	    xm << element if element
	end
                                                                                                                                                 
      }
      # Don't close $stdout
      xm.target!().close if xm.target!.class == File
    end

  end

  module ActAsIzPackPackager
    include Extension

    def package_as_izpack(file_name)
      izpack = IzPackTask.define_task(file_name)
      izpack.enhance do |task|
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