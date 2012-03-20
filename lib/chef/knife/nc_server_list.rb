#
# Author:: tily (<tidnlyam@gmail.com>)
# Copyright:: Copyright (c) 2012 tily
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

require 'chef/knife/nc_base'

class Chef
  class Knife
    class NcServerList < Knife

      include Knife::NcBase

      banner "knife nc server list (options)"

      def run
        $stdout.sync = true

        validate!

        server_list = [
          ui.color('Instance ID', :bold),
          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
          ui.color('SSH Key', :bold),
          ui.color('Security Group', :bold),
          ui.color('State', :bold)
        ]
        connection.describe_instances.reservationSet.item.each do |instance|
          server = instance.instancesSet.item.first
          group = instance.groupSet
          server_list << server.instanceId
          server_list << server.ipAddress.to_s
          server_list << server.privateIpAddress.to_s
          server_list << server.instanceType
          server_list << server.imageId
          server_list << server.keyName
          server_list << (group ? group.item.first.groupId : '')
          server_list << begin
            state = server.instanceState.name
            case state
            when 'sotopped', 'warning', 'waiting', 'creating', 'suspending', 'uploading', 'import_error'
              ui.color(state, :red)
            when 'pending'
              ui.color(state, :yellow)
            else
              ui.color(state, :green)
            end
          end
        end
        puts ui.list(server_list, :columns_across, 8)

      end
    end
  end
end


