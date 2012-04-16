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

describe BuildrIzPack::DebTask do

  def write_files

  it "should throw an error if no control file is given" do
    write_files
    define("foo", :version => "1.0") do
      
      project.package(:deb).postinst = _("postinst")
      project.package(:deb).prerm = _("prerm")
    end
    lambda { project("foo").package(:deb).invoke }.should raise_error(/no control file was defined when packaging as a deb file/)
  end
  
  it "should raise an exception if the control is incorrectly formatted" do
    write_files
    define("foo", :version => "1.0") do
      project.package(:deb).control = _("control2")
      project.package(:deb).postinst = _("postinst")
      project.package(:deb).prerm = _("prerm")
    end
    lambda { project("foo").package(:deb).invoke }.should raise_error(/dpkg failed with this error:/)
  end
  
  it "should give a project the ability to package as deb" do
    write_files
    define("foo", :version => "1.0") do
      project.package(:deb).control = _("control")
      project.package(:deb).postinst = _("postinst")
      project.package(:deb).prerm = _("prerm")
    end
    lambda { project("foo").package(:deb).invoke }.should_not raise_error 
    File.exists?("target/foo-1.0.deb").should be_true
  end
  
  it "should let the user include files into the deb" do
    write_files
    Buildr::write "blah.class", "some class content"
    Buildr::write "folder/file1.class", "some more content"
    Buildr::write "folder/file2.class", "some other content"
    define("foo", :version => "1.0") do
      project.package(:deb).control = _("control")
      project.package(:deb).postinst = _("postinst")
      project.package(:deb).prerm = _("prerm")
      project.package(:deb).include("blah.class", :path => "lib")
      project.package(:deb).include("folder", :as => "otherlib/")
    end
    project("foo").package(:deb).invoke
    lambda { project("foo").package(:deb).invoke }.should_not raise_error 
    File.exists?("target/foo-1.0.deb").should be_true
    #check the contents of the deb file:
    entries = %x[ dpkg --contents target/foo-1.0.deb ].split("\n").collect { |string| /.* (.*)/.match(string)[1]}

    entries.should include("./otherlib/file1.class")
    entries.should include("./otherlib/file2.class")
    entries.should include("./lib/blah.class")
  end
  
  
  it "should let the user override the package name" do
    write_files
    define("foo", :version => "1.0") do
      project.package(:deb, :file => "bar-1.0.deb").tap do |deb|
        deb.control = _("control")
        deb.postinst = _("postinst")
        deb.prerm = _("prerm")
      end
    end
    project("foo").package(:deb, :file => "bar-1.0.deb").invoke
    File.exists?("bar-1.0.deb").should be_true
  end
  
  it 'should change the version in the control file' do
    write_files
    define("foo", :version => "2.0") do
      project.package(:deb).tap do |deb|
        deb.control = _("control")
        deb.postinst = _("postinst")
        deb.prerm = _("prerm")
      end
    end
    project("foo").package(:deb).invoke
    File.exists?( project("foo").package(:deb).to_s).should be_true
    File.exists?("target/foo-2.0.deb-contents/DEBIAN/control").should be_true
    File.read("target/foo-2.0.deb-contents/DEBIAN/control").should match /^Version: 2.0$/
  end
  
  it "should evaluate the contents of the control file" do
    write_files
    define("foo", :version => "2.0") do
      project.package(:deb).tap do |deb|
        deb.control = _("control3")
        deb.postinst = _("postinst")
        deb.prerm = _("prerm")
      end
    end
    MY_CUSTOM_VALUE = "custom"
    project("foo").package(:deb).invoke
    File.exists?( project("foo").package(:deb).to_s).should be_true
    File.exists?("target/foo-2.0.deb-contents/DEBIAN/control").should be_true
    File.read("target/foo-2.0.deb-contents/DEBIAN/control").should match MY_CUSTOM_VALUE
  end
end