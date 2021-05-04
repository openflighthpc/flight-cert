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
        if FlightCert.https_disabled?
          raise GeneralError, 'The HTTPs server is already disabled'
        end

        # Make sure we don't delete actual files; only symlinks.  In practice,
        # this error shouldn't occur.
        FlightCert.config.https_enable_paths.each do |path|
          if File.exists?(path) && !File.symlink?(path)
            raise InternalError, <<~ERROR.chomp
              Cowardly refusing to disable HTTPS as the following file is not linked correctly:
              #{Paint[path, :yellow]}
            ERROR
          end
        end
        FlightCert.config.https_enable_paths.each { |p| FileUtils.rm_f p }

        if FlightCert.run_restart_command
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
