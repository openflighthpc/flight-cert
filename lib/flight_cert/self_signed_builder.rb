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

require 'openssl'

module FlightCert
  SelfSignedBuilder = Struct.new(:domain, :email) do
    def key
      @key ||= OpenSSL::PKey::RSA.new(2048)
    end

    def subject
      "/CN=#{domain}".tap do |str|
        str << "/emailAddress=#{email}" if email
      end
    end

    def certificate
      @certificate ||= OpenSSL::X509::Certificate.new.tap do |cert|
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
        cert.not_before = Time.now
        cert.not_after = Time.now + (10 * 365.25).floor * 24 * 60 * 60 # Valid for 10 years
        cert.public_key = key.public_key
        cert.serial = rand(2**(8*20)-1)
        cert.version = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.add_extension ef.create_extension("basicConstraints","CA:TRUE")
        cert.add_extension ef.create_extension("subjectKeyIdentifier", "hash")
        cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")
        cert.add_extension ef.create_extension("keyUsage","digitalSignature, keyCertSign, cRLSign" )

        cert.sign key, OpenSSL::Digest::SHA256.new
      end
    end

    def to_fullchain
      certificate.to_pem
    end
  end
end
