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
    class NcImageList < Knife

      include Knife::NcBase

      banner "knife nc image list (options)"

      def run
        $stdout.sync = true

        validate!

        image_list = [
          ui.color('Image ID', :bold),
          ui.color('Name', :bold),
          ui.color('Owner', :bold),
          ui.color('State', :bold)
        ]
        connection.describe_images.imagesSet.item.each do |image|
	  image_list << image.imageId
          image_list << image.name
          image_list << "#{image.imageOwnerId} (#{image.imageOwnerAlias})"
          image_list << "#{image.imageState} (#{image.isPublic ? 'public' : 'private'})"
        end
        puts ui.list(image_list, :columns_across, 4)

      end
    end
  end
end


