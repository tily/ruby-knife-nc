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
$:.unshift(File.dirname(__FILE__) + '../../') unless $:.include?(File.dirname(__FILE__) + '../../')
require 'chef/knife'
require 'knife-nc/chef_extensions'

class Chef
  class Knife
    module NcBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'NIFTY'
            require 'readline'
            require 'chef/json_compat'
          end

          option :nc_access_key,
            :short => "-A ACCESS_KEY",
            :long => "--access-key KEY",
            :description => "Your NIFTY Cloud Access Key ID",
            :proc => Proc.new { |key| Chef::Config[:knife][:nc_access_key] = key }

          option :nc_secret_key,
            :short => "-K SECRET_KEY",
            :long => "--secret-key SECRET",
            :description => "Your NIFTY Cloud API Secret Access Key",
            :proc => Proc.new { |key| Chef::Config[:knife][:nc_secret_key] = key }
        end
      end

      def connection
        @connection ||= begin
          connection = NIFTY::Cloud::Base.new(
            :access_key => Chef::Config[:knife][:nc_access_key],
            :secret_key => Chef::Config[:knife][:nc_secret_key]
        )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def validate!(keys=[:nc_access_key, :nc_secret_key])
        errors = []

        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(nc)|(id)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil?
            errors << "You did not provide a valid '#{pretty_key}' value."
          end
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

    end
  end
end


