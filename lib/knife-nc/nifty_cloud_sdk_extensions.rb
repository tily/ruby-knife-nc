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
require 'NIFTY'

class NIFTY::Cloud::Base
  alias original_run_instances run_instances
  alias original_response_generator response_generator
  def run_instances(options)
    options[:password] = 'ignoreme' unless options[:password]
    @user_data = options[:user_data]
    original_run_instances(options)
  end

  def response_generator(params)
    params.delete('Password') if params['Password'] == 'ignoreme'
    if @user_data
      params['UserData'] = extract_user_data(:user_data => @user_data, :base64_encoded => true)
      params['UserData.Encoding'] = 'base64'
    end
    original_response_generator(params)
  end
end
