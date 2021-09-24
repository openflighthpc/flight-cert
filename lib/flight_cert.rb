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
require 'open3'

module FlightCert
  autoload(:Command, 'flight_cert/command')
  autoload(:Commands, 'flight_cert/commands')
  autoload(:VERSION, 'flight_cert/version')
  autoload(:Configuration, 'flight_cert/configuration')

  class << self
    def run_restart_command
      run_command(:restart_command)
    end

    def run_status_command
      run_command(:status_command)
    end

    ##
    # Checks if all the enable https paths have been symlinked
    def https_enabled?
      Flight.config.https_enable_paths.all? { |p| File.symlink?(p) }
    end

    ##
    # Checks if the https server is fully disabled
    # NOTE: This is not the logical opposite of https_enable? due to the
    # technical possibility of a mixed state. However this in practice
    # shouldn't occur.
    def https_disabled?
      !Flight.config.https_enable_paths.any? { |p| File.symlink?(p) }
    end

    private

    def run_command(command_name)
      cmd = Flight.config.send(command_name)
      if cmd.nil? || cmd.empty?
        Flight.logger.info "Command #{command_name.inspect} not set"
        return false
      end

      Flight.logger.info "Running #{command_name.inspect}: (#{cmd.inspect})"
      status = nil
      Bundler.with_unbundled_env do
        _, _, status = Open3.capture3(cmd).tap do |r|
          Flight.logger.info "Exited: #{r.last.exitstatus}"
          Flight.logger.debug "STDOUT: #{r[0]}"
          Flight.logger.debug "STDERR: #{r[1]}"
        end
      end
      status.success?
    end
  end
end
