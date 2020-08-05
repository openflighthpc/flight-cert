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

require_relative '../self_signed_builder'
require 'shellwords'

module FlightCert
  module Commands
    class CertGen < Command
      def run
        process_options
        ensure_domain_is_set
        ensure_letsencrypt_has_an_email
        Config::CACHE.save

        # Generate the certificates
        Config::CACHE.letsencrypt? ? generate_letsencrypt : generate_selfsigned

        # Link the certificates into place
        Config::CACHE.link_certificates

        # Attempts to restart the service
        if File.exists? Config::CACHE.enabled_https_path
          _, _, status = Config::CACHE.run_restart_command
          unless status.success?
            raise GeneralError, <<~ERROR.chomp
              Failed to restart the web server with the new certificate!
            ERROR
          end

        # Notifies the user how to enable https
        else
          $stderr.puts <<~WARN
            The HTTPs server does not appear to be running. It can be enabled with:
            #{Paint["#{Config::CACHE.app_name} enable-https", :yellow]}
          WARN
        end
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
        return if Config::CACHE.domain?
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

      ##
      # Generates a lets encrypt certificate
      def generate_letsencrypt
        # Checks if the external service is running
        _, _, status = Config::CACHE.run_status_command
        unless status.success?
          msg = "The external web service does not appear to be running!"
          if Config::CACHE.start_command_prompt
            msg += "\nPlease start it with:\n#{Paint[Config::CACHE.start_command_prompt, :yellow]}"
          end
          raise GeneralError, msg
        end

        puts "Generating a Let's Encrypt certificate, please wait..."
        cmd = [
          Config::CACHE.certbot_bin,
          'certonly', '-n', '--agree-tos',
          '--domain', Config::CACHE.domain,
          '--email', Config::CACHE.email,
          *Shellwords.shellsplit(Config::CACHE.certbot_plugin_flags)
        ]
        Config::CACHE.logger.info "Command (approx): #{cmd.join(' ')}"
        out, err, status = Open3.capture3(*cmd)
        Config::CACHE.logger.info "Exited: #{status.exitstatus}"
        Config::CACHE.logger.debug "STDOUT: #{out}"
        Config::CACHE.logger.debug "STDERR: #{err}"
        unless status.success?
          raise GeneralError, <<~ERROR.chomp
            Failed to generate the Let's Encrypt certificate with the following error:

            #{err}
          ERROR
        end
      end

      ##
      # Generates a self signed certificate
      def generate_selfsigned
        puts "Generating a self-signed certificate with a 10 year expiry. Please wait..."
        builder = SelfSignedBuilder.new(Config::CACHE.domain, Config::CACHE.email)
        FileUtils.mkdir_p Config::CACHE.selfsigned_dir
        File.write        Config::CACHE.selfsigned_fullchain, builder.to_fullchain
        File.write        Config::CACHE.selfsigned_privkey,   builder.key.to_s
      end
    end
  end
end
