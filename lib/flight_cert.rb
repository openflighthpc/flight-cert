# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
#
# This file is part of Flight Cert.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cert is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cert. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cert, please visit:
# https://github.com/openflighthpc/flight-cert
#==============================================================================
require 'logger'
require 'open3'
require 'active_support/string_inquirer'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/module/delegation'

module FlightCert
  autoload(:Command, 'flight_cert/command')
  autoload(:Commands, 'flight_cert/commands')
  autoload(:VERSION, 'flight_cert/version')
  autoload(:Configuration, 'flight_cert/configuration')

  class << self
    def config
      @config ||= Configuration.load
    end
    alias_method :load_configuration, :config

    def logger
      @logger ||= Logger.new(config.log_path).tap do |log|
        next if config.log_level == 'disabled'

        level =
          case config.log_level
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
          log.level = Logger::ERROR
          log.error "Unrecognized log level: #{log_level}"
        else
          log.level = level
        end
      end
    end

    def run_restart_command
      run_command(:restart_command)
    end

    def run_status_command
      run_command(:status_command)
    end

    ##
    # Checks if all the enable https paths have been symlinked
    def https_enabled?
      config.https_enable_paths.all? { |p| File.symlink?(p) }
    end

    ##
    # Checks if the https server is fully disabled
    # NOTE: This is not the logical opposite of https_enable? due to the
    # technical possibility of a mixed state. However this in practice
    # shouldn't occur.
    def https_disabled?
      !config.https_enable_paths.any? { |p| File.symlink?(p) }
    end

    def env
      @env ||= ActiveSupport::StringInquirer.new(
        ENV["flight_ENVIRONMENT"].presence || "production"
      )
    end

    def root
      @root ||=
        if env.production? && ENV["flight_ROOT"].present?
          File.expand_path(ENV["flight_ROOT"])
        else
          File.expand_path('..', __dir__)
        end
    end

    private

    def run_command(command_name)
      cmd = config.send(command_name)
      if cmd.nil? || cmd.empty?
        logger.info "Command #{command_name.inspect} not set"
        return false
      end

      logger.info "Running #{command_name.inspect}: (#{cmd.inspect})"
      status = nil
      Bundler.with_unbundled_env do
        _, _, status = Open3.capture3(cmd).tap do |r|
          logger.info "Exited: #{r.last.exitstatus}"
          logger.debug "STDOUT: #{r[0]}"
          logger.debug "STDERR: #{r[1]}"
        end
      end
      status.success?
    end
  end
end

# Provides a common interface to details about this application.
#
# Similar in nature to the `Rails` object, it allows access to common objects
# across the code base without having to use dependency injection everywhere.
module Flight
  class << self
    delegate :config, :env, :logger, :root, to: FlightCert
  end
end
