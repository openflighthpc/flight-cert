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

require 'yaml'
require 'logger'
require 'hashie'

require_relative 'errors'

module FlightCert
  class Config < Hashie::Trash
    include Hashie::Extensions::IgnoreUndeclared
    include Hashie::Extensions::Dash::IndifferentAccess

    REFERENCE_PATH  = File.expand_path('../../etc/config.reference', __dir__)
    CONFIG_PATH     = File.expand_path('../../etc/config.yaml', __dir__)

    LETS_ENCRYPT_TYPES  = [
      :lets_encrypt, 'lets-encrypt', 'lets_encrypt', 'letsencrypt', 'letsEncrypt', 'LetsEncrypt', 'LETS_ENCRYPT'
    ]
    SELF_SIGNED_TYPES   = [
      :self_signed,  'self-signed',  'self_signed',  'selfsigned',  'selfSigned',  'SelfSigned',  'SELF_SIGNED'
    ]
    ALL_TYPES = [*LETS_ENCRYPT_TYPES, *SELF_SIGNED_TYPES]

    def self.load_reference(path)
      self.instance_eval(File.read(path), path, 0) if File.exists?(path)
    end

    def self.config(sym, **input_opts)
      opts = input_opts.dup

      # Make keys with defaults required by default
      opts[:required] = true if opts.key? :default && !opts.key?(:required)

      # Defines the underlining property
      property(sym, **opts)

      # Define the truthiness method
      # NOTE: Empty values are not considered truthy
      define_method(:"#{sym}?") do
        value = send(sym)
        if value.respond_to?(:empty?)
          value.empty?
        else
          send(sym) ? true : false
        end
      end
    end

    config :development

    def log_path_or_stderr
      if log_level == 'disabled'
        '/dev/null'
      elsif log_path
        FileUtils.mkdir_p File.dirname(log_path)
        log_path
      else
        $stderr
      end
    end

    def logger
      @logger ||= Logger.new(log_path_or_stderr).tap do |log|
        next if log_level == 'disabled'

        # Determine the level
        level = case log_level
        when 'fatal'
          Logger::FATAL
        when 'error'
          Logger::ERROR
        when 'warn'
          Logger::WARN
        when 'info'
          Logger::INFO
        when 'debug'
          Logger::DEBUG
        end

        if level.nil?
          # Log bad log levels
          log.level = Logger::ERROR
          log.error "Unrecognized log level: #{log_level}"
        else
          # Sets good log levels
          log.level = level
        end
      end
    end

    def lets_encrypt?
      resolved_cert_type == :lets_encrypt
    end

    def self_signed?
      resolved_cert_type == :self_signed
    end

    # NOTE: This method must not be cached! The config is a dynamic object that
    # is updated by scripts. This method must reflect these changes
    def resolved_cert_type
      case cert_type.to_s
      when *LETS_ENCRYPT_TYPES
        :lets_encrypt
      when *SELF_SIGNED_TYPES
        :self_signed
      else
        $stderr.puts <<~WARN.chomp
          An unexpected error has occurred! The previously cached certificate type is unrecognized: #{cert_type}
          Attempting to fallback onto self-signed, your mileage may vary
        WARN
        self.cert_type = 'self-signed'
        :self_signed
      end
    end

    # Loads the reference file
    Config.load_reference REFERENCE_PATH

    # Caches the config
    Config::CACHE = if File.exists? CONFIG_PATH
      data = File.read(CONFIG_PATH)
      Config.new(YAML.load(data, symbolize_names: true)).tap do |c|
        c.logger.info "Loaded Config: #{CONFIG_PATH}"
      end
    else
      Config.new({}).tap do |c|
        c.logger.info "Missing Config: #{CONFIG_PATH}"
      end
    end
  end
end
