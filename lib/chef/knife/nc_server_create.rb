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
    class NcServerCreate < Knife

      include Knife::NcBase

      deps do
        require 'NIFTY'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife nc server create INSTANCE_ID (options)"

      attr_accessor :initial_sleep_delay

      option :nc_instance_type,
        :short => "-T INSTANCE_TYPE",
        :long => "--instance-type INSTANCE_TYPE",
        :description => "The instance type of server (small, medium, etc)",
        :proc => Proc.new { |t| Chef::Config[:knife][:nc_instance_type] = t },
        :default => "small"

      option :nc_image_id,
        :short => "-I IMAGE_ID",
        :long => "--image IMAGE_ID",
        :description => "The Image ID for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:nc_image_id] = i }

      option :security_group,
        :short => "-G GROUP",
        :long => "--group GROUP",
        :description => "The security group for this server"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :nc_ssh_key_id,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :description => "The NIFTY Cloud SSH key id",
        :proc => Proc.new { |key| Chef::Config[:knife][:nc_ssh_key_id] = key }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_passphrase,
        :short => "-R PASSPHRASE",
        :long => "--ssh-passphrase PASSPHRASE",
        :description => "The ssh passphrase",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_passphrase] = key }

      option :ssh_locally,
        :short => "-L",
        :long => "--ssh-locally",
        :description => "bootstrap via ssh using private IP address"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :nc_bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:nc_bootstrap_version] = v }

      option :nc_distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :proc => Proc.new { |d| Chef::Config[:knife][:nc_distro] = d }

      option :nc_template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:nc_template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      option :nc_user_data,
        :long => "--user-data USER_DATA_FILE",
        :short => "-U USER_DATA_FILE",
        :description => "The NIFTY Cloud User Data file to provision the instance with",
        :proc => Proc.new { |m| Chef::Config[:knife][:nc_user_data] = m },
        :default => nil

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true
        NIFTY::LOG.level = Logger::DEBUG

        validate!

        msg_pair("Instance ID", @name_args.first)
        msg_pair("Instance Type", locate_config_value(:nc_instance_type))
        msg_pair("Image", locate_config_value(:nc_image_id))
        msg_pair("SSH Key", locate_config_value(:nc_ssh_key_id))
        msg_pair("Security Group", config[:security_group])

        puts "\n"
        confirm("Do you really want to create this server")

        server = connection.run_instances(create_server_def).instancesSet.item.first

        msg_pair("Instance ID", server.instanceId)
        msg_pair("Instance Type", server.instanceType)
        msg_pair("Image", server.imageId)
        msg_pair("SSH Key", server.keyName)

        print "\n#{ui.color("Waiting for server", :magenta)}"

        # wait for it to be ready to do stuff
        while server.instanceState.name != 'running'
          print "."
          server = connection.describe_instances(:instance_id => server.instanceId).reservationSet.item.first.instancesSet.item.first
          sleep 5
        end

        puts("done\n")
        
        msg_pair("Public IP Address", server.ipAddress)
        msg_pair("Private IP Address", server.privateIpAddress)

        ssh_ip_address = config[:ssh_locally] ? server.privateIpAddress : server.ipAddress
        print "\n#{ui.color("Waiting for sshd", :magenta)} (using #{ssh_ip_address})"
        
        print(".") until tcp_test_ssh(ssh_ip_address) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }

        bootstrap_for_node(server, ssh_ip_address).run

        puts "\n"
        msg_pair("Instance ID", server.instanceId)
        msg_pair("Instance Type", server.instanceType)
        msg_pair("Image ID", server.imageId)
        msg_pair("Security Group", config[:security_group])
        msg_pair("SSH Key", server.keyName)
        msg_pair("Public IP Address", server.ipAddress)
        msg_pair("Private IP Address", server.privateIpAddress)
        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", config[:run_list].join(', '))
      end

      def bootstrap_for_node(server,fqdn)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [fqdn]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_password] = config[:ssh_password]
        bootstrap.config[:ssh_passphrase] = config[:ssh_passphrase]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.instanceId
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:nc_bootstrap_version)

        image_id = locate_config_value(:nc_image_id)
	if locate_config_value(:nc_distro)
          bootstrap.config[:distro] = locate_config_value(:nc_distro)
        elsif %w(1 2 6 7 13 14).include?(image_id)
          bootstrap.config[:distro] = 'nc-centos5-gems'
        elsif image_id == '17'
          bootstrap.config[:distro] = 'ubuntu10.04-gems'
        elsif image_id == '21'
          bootstrap.config[:distro] = 'nc-centos6-gems'
	else
          bootstrap.config[:distro] = 'nc-centos5-gems'
        end

        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:nc_template_file)
        bootstrap.config[:environment] = config[:environment]
        bootstrap
      end

      def image
        @image ||= connection.describe_images(:image_id => locate_config_value(:nc_image_id)).imagesSet.item.first
      end

      def validate!
        super([:nc_image_id, :nc_ssh_key_id, :nc_access_key, :nc_secret_key])

        errors = []

        if @name_args.empty?
          errors << "You have not provided a valid instance ID."
        end

        if config[:security_group].nil?
          errors << "You have not provided a valid Security Group."
        end

        [:identity_file, :nc_template_file, :nc_user_data].each do |x|
          if (path = locate_config_value(x)) && !File.exists?(path)
            errors << "File does not exist: #{path}"
          end
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end
      
      def create_server_def
        server_def = {
          :instance_id => @name_args.first,
          :image_id => locate_config_value(:nc_image_id),
          :instance_type => locate_config_value(:nc_instance_type),
          :security_group => config[:security_group],
          :key_name => Chef::Config[:knife][:nc_ssh_key_id],
          :disable_api_termination => false # for 'knife nc server delete' command
        }

        if Chef::Config[:knife][:nc_user_data]
          begin
            server_def.merge!(:user_data => File.read(locate_config_value(:nc_user_data)))
          rescue
            ui.warn("Cannot read #{Chef::Config[:knife][:nc_user_data]}: #{$!.inspect}. Ignoring option.")
          end
        end

        server_def
      end
    end
  end
end
