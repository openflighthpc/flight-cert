#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of FlightCert.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# FlightCert is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with FlightCert. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on FlightCert, please visit:
# https://github.com/openflighthpc/flight-cert
#==============================================================================

module FlightCert
  module Commands
    class DisableHttps < Command
      def run
        unless File.exists? Config::CACHE.enabled_https_path
          raise GeneralError, 'The HTTPs server is already disabled'
        end

        FileUtils.mkdir_p File.dirname(Config::CACHE.disabled_https_path)
        FileUtils.mv Config::CACHE.enabled_https_path, Config::CACHE.disabled_https_path

        # Attempts to restart the server
        _, _, status = Config::CACHE.run_restart_command
        if status.success?
          puts 'HTTPs has been disabled'
        else
          raise GeneralError, <<~ERROR.chomp
            HTTPs has been disabled but the web server failed to restart!
          ERROR
        end
      end
    end
  end
end

