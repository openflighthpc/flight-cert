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
  class Error < RuntimeError
    def self.define_class(code)
      Class.new(self).tap do |klass|
        klass.instance_variable_set(:@exit_code, code)
      end
    end

    def self.exit_code
      @exit_code || begin
        superclass.respond_to?(:exit_code) ? superclass.exit_code : 2
      end
    end

    def exit_code
      self.class.exit_code
    end
  end

  # NOTE: SystemError is used for backwards compatibility with errors which
  #       aren't internal but still exit 1
  SystemError = Error.define_class(1)
  InternalError = Error.define_class(1)
  GeneralError = Error.define_class(2)
  InputError = GeneralError.define_class(3)

  class InteractiveOnly < InputError
    MSG = 'This command requires an interactive terminal'

    def initialize(msg = MSG)
      super
    end
  end

  MissingError = GeneralError.define_class(20)
end
