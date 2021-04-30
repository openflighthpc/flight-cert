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

    root_path File.expand_path('../..', __dir__)

    env_var_prefix 'flight_CERT'

    LOCAL_CONFIG_FILE = File.expand_path('etc/flight-cert.local.yaml', root_path)
    config_files File.expand_path('etc/flight-cert.yaml', root_path),
                 File.expand_path('etc/flight-cert.development.yaml', root_path),
                 LOCAL_CONFIG_FILE

    attribute :program_name, default: 'bin/cert'
    attribute :program_application, default: 'Flight WWW'
    attribute :program_description, default: 'Manage the HTTPs server and SSL certificates'

    attribute :cert_type, default: 'lets_encrypt'
    attribute :email, required: false
    attribute :domain, required: false

    attribute :selfsigned_dir, default: 'self_signed',
      transform: relative_to(root_path)
    attribute :ssl_fullchain, default: 'ssl/fullchain.pem',
      transform: relative_to(root_path)
    attribute :ssl_privkey, default: 'ssl/privkey.pem',
      transform: relative_to(root_path)
    attribute :letsencrypt_live_dir, default: '/etc/letsencrypt/live',
      transform: relative_to(root_path)

    attribute :certbot_bin, default: '/usr/local/bin/certbot'
      # transform: relative_to(root_path)
    attribute :certbot_plugin_flags, default: '--nginx'

    attribute :cron_path, default: '/etc/cron.daily/flight-cert'
    attribute :cron_script, required: false

    attribute :https_enable_paths, default: []

    attribute :status_command, default: 'echo No Status Command!; exit 1'
    attribute :restart_command, default: 'echo No Restart Command!; exit 1'
    attribute :start_command_prompt, required: false

    attribute :log_path, required: false,
      default: 'var/log/flight-cert.log',
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
    attribute :development, default: false, required: false

    ##
    # Checks if all the enable https paths have been symlinked
    def https_enabled?
      https_enable_paths.all? { |p| File.symlink?(p) }
    end

    ##
    # Checks if the https server is fully disabled
    # NOTE: This is not the logical opposite of https_enable? due to the
    # technical possibility of a mixed state. However this in practice
    # shouldn't occur.
    def https_disabled?
      !https_enable_paths.any? { |p| File.symlink?(p) }
    end

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

    # The configuration for the email and domain can be provided interactively
    # when generating a certificate.  Any such values are saved separately
    # from the main configuration.
    def save_email_and_domain
      local_config = from_config_file(LOCAL_CONFIG_FILE)
      new_local_config = local_config.merge('email' => email, 'domain' => domain)
      File.write LOCAL_CONFIG_FILE, YAML.dump(new_local_config)
    end

    private

    def from_config_file(config_file)
      return {} unless File.exists?(config_file)
      yaml =
        begin
          YAML.load_file(config_file)
        rescue ::Psych::SyntaxError
          raise "YAML syntax error occurred while parsing #{config_file}. " \
            "Please note that YAML must be consistently indented using spaces. Tabs are not allowed. " \
            "Error: #{$!.message}"
        end
      FlightConfiguration::DeepStringifyKeys.stringify(yaml) || {}
    end
  end
end
