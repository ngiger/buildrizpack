#encoding: utf-8
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

require File.join(File.dirname(__FILE__), '../spec_helpers')

describe BuildrIzPack::IzPackTask do

  def writeJavaMain(filename)
    Buildr::write(filename, "public class Main { public static void main(String[] args) {}}")
  end

  def define_project(project_name='foo')
    myPath = "src/main/java/Main.java"
    writeJavaMain(myPath)
    @project = define(project_name, :version => "1.0.0.001") do
      x = path_to(:sources, :main, :java)+'/**/*.java'
      package(:jar)
      package(:izpack).include(package(:jar))
    end
  end

  def writeSimpleInstaller(filename)
    content = %(<?xml version="1.0" encoding="utf-8" standalone="yes" ?>
<installation version="1.0">
	<info>
		<appname>demo app</appname>
		<appversion>7.6.5</appversion>
	</info>
	<guiprefs width="700" height="520" resizable="yes" />
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
      puts "writeSimpleInstaller wrote #{File.expand_path(filename)}"
      Buildr::write(filename, content)
  end
  
  it "should generate an installer jar" do
    define_project
    @project.package(:izpack).invoke
    @path = @project.package(:jar).to_s
    File.exists?(@path).should be_true
    @path.to_s.should include(".jar")
    Zip::ZipFile.open(@path) do |zip|
      zip.find_entry("Main.class").should_not be_nil
      zip.find_entry("META-INF/MANIFEST.MF").should_not be_nil
    end
    File.exists?(@path).should be_true
    @instPath = File.join(@project.path_to(:target, :main), "#{@project.name}-#{@project.version}.izpack.jar")
    File.exists?(@instPath).should be_true
  end 
  
  it "should use the provided install.xml" do
    define_project('withXml')
    xmlPath = File.join(@project.path_to(:target), "install.xml")
    writeSimpleInstaller(xmlPath)
    @project.package(:izpack).input = xmlPath
    @project.package(:izpack).invoke
    @instPath = File.join(@project.path_to(:target, :main), "#{@project.name}-#{@project.version}.izpack.jar")
    File.exists?(@instPath).should be_true
  end 
 
  it "must include at least one file" do
    @project = define('nofile', :version => "1.0.2") do
      package(:izpack)
    end
    lambda { project("nofile").package(:izpack).invoke }.should raise_error(/You must include at least one file to create an izPack installer/)
  end 
  
  it "should be possible to add several files to several packs" do
    define_project('severalPacks')
    @project.package(:izpack).locales = ['eng', 'fra', 'deu']
    Buildr.write(@project.path_to(:target)+"/1_5.txt", "This is file 1_5.txt")
    Buildr.write(@project.path_to(:target)+"/3_7.txt", "This is file 3_7.txt")
    s = ''
    xm = Builder::XmlMarkup.new(:target=>s)
    xm.packs {
    xm.pack('name' => 'pack_3', 'required' => 'yes') {
						    xm.description("Niklaus ist am Testen")
	xm.file('src'=> @project.path_to(:target)+"/1_5.txt", 'targetdir' =>'1/5')
	xm.file('src'=> @project.path_to(:target)+"/3_7.txt", 'targetdir' =>'3/7')
      }
    }
    
    @project.package(:izpack).packs = s
    s = ''
    xm = Builder::XmlMarkup.new(:target=>s)
    xm.native('type'=>'izpack', 'name'=>'ShellLink.dll')
    @project.package(:izpack).native = s
    @project.package(:izpack).invoke
    File.exists?(@project.package(:izpack).input).should be_true
    content = IO.readlines(@project.package(:izpack).input)
    content.join.should match('pack_3')
    content.join.should match('1_5.txt')
    content.join.should match('3/7')
    content.join.should match('<native ')
    
    @instPath = File.join(@project.path_to(:target, :main), "#{@project.name}-#{@project.version}.izpack.jar")
    File.exists?(@instPath).should be_true
  end

end