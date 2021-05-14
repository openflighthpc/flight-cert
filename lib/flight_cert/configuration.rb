#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
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

require 'flight_configuration'
require_relative 'errors'

module FlightCert
  class Configuration
    extend FlightConfiguration::DSL

    LETS_ENCRYPT_TYPES  = [
      :lets_encrypt, 'lets-encrypt', 'lets_encrypt', 'letsencrypt',
      'letsEncrypt', 'LetsEncrypt', 'LETS_ENCRYPT'
    ]
    SELF_SIGNED_TYPES   = [
      :self_signed,  'self-signed',  'self_signed',  'selfsigned',
      'selfSigned',  'SelfSigned',  'SELF_SIGNED'
    ]
    ALL_CERT_TYPES = [*LETS_ENCRYPT_TYPES, *SELF_SIGNED_TYPES]

    application_name 'cert'

    attribute :program_name, default: 'bin/cert'
    attribute :program_application, default: 'Flight WWW'
    attribute :program_description, default: 'Manage the HTTPs server and SSL certificates'

    attribute :cert_type, default: 'lets_encrypt'
    attribute :email, required: false
    attribute :domain, required: false

    attribute :selfsigned_dir, default: 'etc/www/self_signed',
      transform: relative_to(root_path)
    attribute :ssl_fullchain, default: 'etc/www/ssl/fullchain.pem',
      transform: relative_to(root_path)
    attribute :ssl_privkey, default: 'etc/www/ssl/key.pem',
      transform: relative_to(root_path)
    attribute :letsencrypt_live_dir, default: 'etc/letsencrypt/live',
      transform: relative_to(root_path)

    attribute :certbot_bin, default: '/usr/local/bin/certbot'
    attribute :certbot_plugin_flags, default: '--nginx'

    attribute :cron_path, default: 'etc/cron/weekly/cert-renewal',
      transform: relative_to(root_path)
    attribute :cron_script, required: false

    attribute :https_enable_paths, default: [],
      transform: ->(paths) do
        paths.map {|p| relative_to(root_path).call(p)}
      end

    attribute :status_command, required: false
    attribute :restart_command, required: false
    attribute :start_command_prompt, required: false

    attribute :log_path, required: false,
      default: "var/log/#{application_name}.log",
      transform: ->(path) do
        if path
          relative_to(root_path).call(path).tap do |full_path|
            FileUtils.mkdir_p File.dirname(full_path)
          end
        else
          $stderr
        end
      end
    attribute :log_level, default: 'error'

    def selfsigned_privkey
      File.join(selfsigned_dir, 'privkey.pem')
    end

    def selfsigned_fullchain
      File.join(selfsigned_dir, 'fullchain.pem')
    end

    def letsencrypt_fullchain
      File.join(letsencrypt_live_dir, domain, 'fullchain.pem')
    end

    def letsencrypt_privkey
      File.join(letsencrypt_live_dir, domain, 'privkey.pem')
    end

    def letsencrypt?
      resolved_cert_type == :lets_encrypt
    end

    def selfsigned?
      resolved_cert_type == :self_signed
    end

    def resolved_cert_type
      case cert_type.to_s
      when *LETS_ENCRYPT_TYPES
        :lets_encrypt
      when *SELF_SIGNED_TYPES
        :self_signed
      else
        $stderr.puts <<~WARN.chomp
          An unexpected error has occurred! Unrecognized certificate type: #{cert_type}
          Attempting to fallback to self-signed, your mileage may vary.
        WARN
        self.cert_type = 'self-signed'
        :self_signed
      end
    end

    # The configuration for the certificate type, email and domain can be
    # provided interactively when generating a certificate.  Any such values
    # are saved separately from the main configuration.
    def save_local_configuration
      local_config = self.class.from_config_file(local_config_file)
      new_local_config = local_config.merge(
        'email' => email, 'domain' => domain, 'cert_type' => cert_type
      )
      File.write local_config_file, YAML.dump(new_local_config)
    end

    private

    def local_config_file
      self.class.config_files.detect { |cf| cf.to_s.match?(/local.yaml$/) }
    end
  end
end
