#==============================================================================
## Copyright (C) 2020-present Alces Flight Ltd.
##
## This file is part of FlightCert.
##
## This program and the accompanying materials are made available under
## the terms of the Eclipse Public License 2.0 which is available at
## <https://www.eclipse.org/legal/epl-2.0>, or alternative license
## terms made available by Alces Flight Ltd - please direct inquiries
## about licensing to licensing@alces-flight.com.
##
## FlightCert is distributed in the hope that it will be useful, but
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
## IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
## OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
## PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
## details.
##
## You should have received a copy of the Eclipse Public License 2.0
## along with FlightCert. If not, see:
##
##  https://opensource.org/licenses/EPL-2.0
##
## For more information on FlightCert, please visit:
## https://github.com/openflighthpc/flight-cert
##==============================================================================

module FlightCert
  module Commands
    class CertInstall < Command
      def run
        key = options.key
        fullchain = options.fullchain
        set_cert_type
        
        # Create symlinks for certificates
        link_certificates(key, fullchain)

        # Attempt to restart service (if required)
        if FlightCert.https_enabled? && FlightCert.run_status_command
          unless FlightCert.run_restart_command
            raise GeneralError, <<~ERROR.chomp
              Failed to restart the web server with the new certificate!
            ERROR
          end
        end

        # Notify the restart has been skipped as the service has been stopped
        unless FlightCert.https_enabled?
          $stderr.puts <<~WARN
            You can now enable the HTTPS server with:
            #{Paint["#{Flight.config.program_name} enable-https", :yellow]}
          WARN
        end
      end

      private

      def set_cert_type
        Flight.config.cert_type = :self_generated
      end

      def link_certificates(key, fullchain)
        ssl_privkey = Flight.config.ssl_privkey
        ssl_fullchain = Flight.config.ssl_fullchain

        FileUtils.mkdir_p File.dirname(ssl_privkey)
        FileUtils.mkdir_p File.dirname(ssl_fullchain)
        FileUtils.ln_sf key, ssl_privkey
        FileUtils.ln_sf fullchain, ssl_fullchain
      end
    end
  end
end
