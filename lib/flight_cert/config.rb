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
require 'xdg'

module FlightCert
  module Config
    include Hashie::Extensions::IgnoreUndeclared
    include Hashie::Extensions::Dash::IndifferentAccess

    REFERENCE_PATH  = File.expand_path('../../etc/config.reference', __dir__)
    CONFIG_PATH     = File.expand_path('../../etc/config.yaml', __dir__)

    def self.config(sym, **input_opts)
      opts = input_opts.dup

      # Make keys with defaults required by default
      opts[:required] = true if opts.key? :default && !opts.key?(:required)

      bang_nil_result = if transform = opts[:transform_with]
        # Set the bang method nil result from the transform
        transform.call(nil)
      else
        # By default convert empty string to nil
        opts[:transform_with] = ->(v) { v == '' ? nil : v }

        # Return nil as empty string through the bang method
        ''
      end

      # Defines the underlining property
      property(sym, **opts)

      # Return the bang result through the bang method if nil
      define_method(:"#{sym}!") do
        value = send(sym)
        value.nil? ? bang_nil_result : value
      end

      # Define the truthiness method
      define_method(:"#{sym}?") { send(sym) ? true : false }
    end
  end
end
