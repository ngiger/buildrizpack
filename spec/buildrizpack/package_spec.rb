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
  end

  it "should throw an error if no control file is given" do
    write_files
    define("foo", :version => "1.0") do
      project.package(:izpack).postinst = _("postinst")
      project.package(:izpack).prerm = _("prerm")
    end
    lambda { project("foo").package(:izpack).invoke }.should raise_error(/no control file was defined when packaging as a izpack file/)
  end
end