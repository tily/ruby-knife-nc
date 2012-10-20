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

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class NcServerDelete < Knife

      include Knife::NcBase

      banner "knife nc server delete INSTANCE_ID_1 [INSTANCE_ID_2 ...] (options)"

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the NIFTY Cloud node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      option :force,
        :long => "--force",
        :default => false,
        :description => "Force to delete server by changing the server's disableApiTermination attribute to false."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run

        validate!

        @name_args.each do |instance_id|

          begin
            server = connection.describe_instances(:instance_id => instance_id).reservationSet.item.first.instancesSet.item.first

            msg_pair("Instance ID", server.instanceId)
            msg_pair("Instance Type", server.instanceType)
            msg_pair("Image ID", server.imageId)
            #msg_pair("Security Groups", server.groups.join(", "))
            msg_pair("SSH Key", server.keyName)
            msg_pair("Root Device Type", server.root_device_type)
            msg_pair("Public IP Address", server.ipAddress)
            msg_pair("Private IP Address", server.privateIpAddress)

            puts "\n"
            confirm("Do you really want to delete this server")

            if server.instanceState.name != 'stopped'
              print "\n#{ui.color("Waiting for server to shutdown", :magenta)}"
              connection.stop_instances(:instance_id => instance_id, :force => true)
              while server.instanceState.name != 'stopped'
                print "."
                server = connection.describe_instances(:instance_id => instance_id).reservationSet.item.first.instancesSet.item.first
                sleep 5
              end
              puts("done\n")
            end

            attribute = connection.describe_instance_attribute(:instance_id => instance_id, :attribute => 'disableApiTermination')
            if attribute.disableApiTermination.value != 'false'
              if config[:force] == false
                ui.error("Server's 'disableApiTermination' attribute is true. Use --force option to delete server.")
                exit 1
              else
                print "\n#{ui.color("Enabling API termination for server", :magenta)}"
                connection.modify_instance_attribute(:instance_id => instance_id, :attribute => 'disableApiTermination', :value => 'false')
                while attribute.disableApiTermination.value != 'false'
                  print "."
                  attribute = connection.describe_instance_attribute(:instance_id => instance_id, :attribute => 'disableApiTermination')
                  sleep 5
                end
                puts("done\n")
              end
            end

            connection.terminate_instances(:instance_id => instance_id)

            ui.warn("Deleted server #{server.id}")

            if config[:purge]
              thing_to_delete = config[:chef_node_name] || instance_id
              destroy_item(Chef::Node, thing_to_delete, "node")
              destroy_item(Chef::ApiClient, thing_to_delete, "client")
            else
              ui.warn("Corresponding node and client for the #{instance_id} server were not deleted and remain registered with the Chef Server")
            end

          rescue NoMethodError
            ui.error("Could not locate server '#{instance_id}'.  Please verify it was provisioned in the '#{locate_config_value(:region)}' region.")
          end
        end
      end

    end
  end
end
