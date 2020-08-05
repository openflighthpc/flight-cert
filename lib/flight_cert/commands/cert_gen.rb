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
    class CertGen < Command
      def run
        process_options
        ensure_domain_is_set
        ensure_letsencrypt_has_an_email
        Config::CACHE.save
      end

      ##
      # Updates the internal config with the new option flags
      def process_options
        if options.cert_type && Config::ALL_TYPES.include?(options.cert_type)
          Config::CACHE.cert_type = options.cert_type
        elsif options.cert_type
          raise InputError, <<~ERROR.chomp
            Unrecognized certificate type: #{options.cert_type}
            Please select either: lets-encrypt or self-signed
          ERROR
        end


        # Updates the email field
        if options.email&.empty?
          $stderr.puts <<~ERROR.chomp
            Clearing the email setting...
          ERROR
          Config::CACHE.delete(:email)
        elsif options.email
          Config::CACHE.email = options.email
        end

        # Updates the domain field
        if options.domain&.empty?
          $stderr.puts <<~ERROR.chomp
            Clearing the domain setting...
          ERROR
          Config::CACHE.delete(:domain)
        elsif options.domain
          Config::CACHE.domain  = options.domain
        end
      end

      ##
      # Defaults the domain to the hostname FQDN if unset
      def ensure_domain_is_set
        Config::CACHE.domain = `hostname --fqdn`.chomp
        $stderr.puts <<~ERROR.chomp
          Reverting to the default domain: #{Config::CACHE.domain}
        ERROR
      end

      ##
      # Errors if the email is unset for LetsEncrypt certificates
      def ensure_letsencrypt_has_an_email
        return if Config::CACHE.email? || !Config::CACHE.letsencrypt?
        puts <<~ERROR.chomp
          Let's Encrypt  certificates require an email address!
          Please provide the following flag: #{Paint['--email EMAIL', :yellow]}
        ERROR
        exit 1
      end
    end
  end
end
