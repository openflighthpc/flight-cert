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
    class CronRenewal < Command
      def run
        if options.disable && File.exists?(Config::CACHE.cron_path)
          FileUtils.rm Config::CACHE.cron_path
          puts <<~INFO.chomp
            Automatic renewal has been disabled
          INFO
        elsif options.disable
          raise InputError, <<~WARN.chomp
            Automatic renewal is already disabled!
          WARN
        elsif Config::CACHE.selfsigned?
           raise SystemError, <<~ERROR.chomp
            Automatic renewal is not support for self-signed certificates!
          ERROR
          exit 1
        elsif File.exists? Config::CACHE.cron_path
          raise InputError, <<~WARN.chomp
            Automatic renewal is already enabled! It can be disabled with:
            #{Paint["#{Config::CACHE.app_name} cron-renewal --disable", :yellow]}
          WARN
        elsif Config::CACHE.cron_script
          File.write Config::CACHE.cron_path, Config::CACHE.cron_script
          puts <<~INFO.chomp
            Automatic renewal has been enabled
          INFO
        else
          raise InternalError, <<~ERROR.chomp
            Failed to enable automatic renewal as the 'cron_script' has not been set!
            Please contact your system administrator for further assistance.
          ERROR
        end
      end
    end
  end
end
