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
    class EnableHttps < Command
      def run
        unless ssl_certs_exist?
          raise GeneralError, <<~ERROR.chomp
            In order to enable HTTPs a set of SSL certificates need to be generated.
            Please run the following to generate the certificates with Let's Encrypt:
            #{Paint["#{FlightCert.config.program_name} cert-gen --cert-type lets-encrypt --domain DOMAIN --email EMAIL", :yellow]}
          ERROR
        end

        if FlightCert.https_enabled?
          raise GeneralError, 'The HTTPs server is already enabled'
        end

        # Ensure no data is going to be overridden.  We want to enable HTTPS
        # only by managing symlinks.
        FlightCert.config.https_enable_paths.each do |path|
          if File.exists?(path) && !File.symlink?(path)
            raise InternalError, <<~ERROR.chomp
              Cowardly refusing to enable HTTPS as the following file already exists:
              #{Paint[path, :yellow]}
            ERROR
          end
        end
        FlightCert.config.https_enable_paths.each do |path|
          FileUtils.ln_sf "#{path}.disabled", path
        end

        unless FlightCert.https_enabled?
          raise GeneralError, 'Failed to enable HTTPS'
        end

        # Attempt to restart the service if required
        if FlightCert.run_status_command
          raise GeneralError, <<~ERROR.chomp unless FlightCert.run_restart_command
            HTTPs has been enabled but the web server failed to restart!
            HTTPs maybe disabled again with:
          #{Paint["#{FlightCert.config.program_name} disable-https", :yellow]}
          ERROR
        end

        puts 'HTTPs has been enabled'
      end

      private

      def ssl_certs_exist?
        File.exists?(FlightCert.config.ssl_fullchain) &&
          File.exists?(FlightCert.config.ssl_privkey)
      end
    end
  end
end
