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

require 'dotenv'
require 'flight_configuration'
require_relative 'errors'

module FlightCert
  class Configuration
    include FlightConfiguration::DSL

    LETS_ENCRYPT_TYPES  = [
      :lets_encrypt, 'lets-encrypt', 'lets_encrypt', 'letsencrypt',
      'letsEncrypt', 'LetsEncrypt', 'LETS_ENCRYPT'
    ]
    SELF_SIGNED_TYPES   = [
      :self_signed,  'self-signed',  'self_signed',  'selfsigned',
      'selfSigned',  'SelfSigned',  'SELF_SIGNED'
    ]
    ALL_CERT_TYPES = [*LETS_ENCRYPT_TYPES, *SELF_SIGNED_TYPES]

    RC = Dotenv.parse(File.join(Flight.root, 'etc/web-suite.rc'))

    application_name 'cert'

    user_config_files false

    attribute :program_name, default: 'bin/cert'
    attribute :program_application, default: 'Flight WWW'
    attribute :program_description, default: 'Manage the HTTPS server and SSL certificates'

    attribute :cert_type, default: 'lets_encrypt'
    attribute :email, required: false
    attribute :domain, required: false, default: RC['flight_WEB_SUITE_domain'],
      env_var: false

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

    class << self
      # The save_local_configuration method requires access to this class
      # method.
      public :from_config_file
    end

    # The configuration for the certificate type, email and domain can be
    # provided interactively when generating a certificate.  Any such values
    # are saved separately from the main configuration.
    def save_local_configuration
      core_config = self.class.from_config_file(core_config_file)
      new_config = self.class.from_config_file(local_config_file)
        .merge('email' => email, 'domain' => domain, 'cert_type' => cert_type)

      # There are some hoops to jump through with regard to the domain.
      #
      # There are four sources from which the domain can be taken:
      #
      # 1. The `RC` file
      # 2. `cert.yaml` (aka core config file)
      # 3. `cert.local.yaml` (aka local config file)
      # 4. The `--domain` CLI option.
      #
      # If the domain comes from (3) or (4) we wish to save it to (3) unless
      # it is the same as the highest precedent value from (1) or (2).
      # 
      # There are actually two more sources: the `cert.#{Flight.env}.yaml` and
      # `cert.#{Flight.env}.local.yaml` files.  We currently ignore.
      if core_config.key? 'domain'
        new_config.delete('domain') if new_config['domain'] == core_config['domain']
      else
        new_config.delete('domain') if new_config['domain'] == RC['flight_WEB_SUITE_domain']
      end

      File.write local_config_file, YAML.dump(new_config)
    end

    private

    def core_config_file
      self.class.config_files.first
    end

    def local_config_file
      self.class.config_files.detect { |cf| cf.to_s.match?(/local.yaml$/) }
    end
  end
end
