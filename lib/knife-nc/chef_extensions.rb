#
# Author:: tily (<tidnlyam@gmail.com>)
# Copyright:: Copyright (c) 2011 tily
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'chef/knife'
require 'chef/knife/ssh'
require 'chef/knife/bootstrap'

class Chef::Knife
  class Ssh
    alias original_session_from_list session_from_list

    option :ssh_passphrase,
      :long => "--ssh-passphrase PASSPHRASE",
      :description => "Your SSH Passphrase",
      :proc => Proc.new { |key| Chef::Config[:knife][:ssh_passphrase] = key }

    def session_from_list(list)
      session = original_session_from_list(list)
      session.servers.each do |server|
        server.options[:passphrase] = config[:ssh_passphrase]
      end
      session
    end
  end

  class Bootstrap
    alias original_knife_ssh knife_ssh

    option :ssh_passphrase,
      :long => "--ssh-passphrase PASSPHRASE",
      :description => "Your SSH Passphrase",
      :proc => Proc.new { |key| Chef::Config[:knife][:ssh_passphrase] = key }

    def knife_ssh
      ssh = original_knife_ssh
      ssh.config[:ssh_passphrase] = config[:ssh_passphrase]
      ssh
    end
  end
end
