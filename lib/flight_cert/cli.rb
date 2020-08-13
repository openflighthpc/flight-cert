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

require_relative 'commands'
require_relative 'version'
require_relative 'config'

require 'commander'

module FlightCert
  module CLI
    extend Commander::CLI

    program :application, "Flight WWW"
    program :name, Config::CACHE.app_name
    program :version, "v#{FlightCert::VERSION}"
    program :description, 'Manage the HTTPs server and SSL certificates'
    program :help_paging, false
    default_command :help

    if ENV['TERM'] !~ /^xterm/ && ENV['TERM'] !~ /rxvt/ && ENV['TERM'] !~ /256color/
      Paint.mode = 0
    end

    def self.create_command(name, args_str = '')
      command(name) do |c|
        c.syntax = "#{program :name} #{name} #{args_str}"
        c.hidden = true if name.split.length > 1

        c.action do |args, opts|
          Commands.build(name, *args, **opts.to_h).run!
        end

        yield c if block_given?
      end
    end

    create_command 'cert-gen' do |c|
      c.summary = 'Generate and renew SSL certificates'
      c.description = <<~DESC.chomp
        By default the HTTPS server is disabled as it requires an SSL certificate.
        The '#{Config::CACHE.app_name}' utilities support the generation of Let's Encrypt and
        self-signed certificates.  We recommended that a Let's Encrypt certificate
        is generated where possible.

        In order to generate a Let's Encrypt certificate, you will require a
        publicly available DNS entry and an email address.  The HTTP server will
        also need to be running to allow Let's Encrypt to successfully perform a DNS
        challenge.  Once ready, A Let's Encrypt certificate can be generated with
        the following command:

        '#{Config::CACHE.app_name} cert-gen --cert-type lets-encrypt --domain DOMAIN --email EMAIL'

        Alternatively, a self-signed SSL certificate valid for 10 years can be
        generated, by running the following command:

        '#{Config::CACHE.app_name} cert-gen --cert-type self-signed'
      DESC
      c.slop.string '--cert-type', 'Select the certificate type: lets-encrypt|self-signed'
      c.slop.string '--domain', 'The domain associated with the certificate'
      c.slop.string '--email', "The email address associated with the Let's Encrypt certificate. Use empty string to unset"
      c.slop.bool '--config-only', 'Only update the internal configuration, skips certificate generation'
    end

    create_command 'cron-renewal' do |c|
      c.summary = 'Manage automatic renewal of SSL certificates'
      c.description = <<~DESC.chomp
        A Let's Encrypt certificate will need to be periodically renewed.  You
        can enable automatic renewal of Let's Encrypt certificates by running:
        '#{Config::CACHE.app_name} cron-renewal'

        Self-signed certificates are valid for 10 years and automatic renewal is not
        supported.
      DESC
      c.slop.bool '--disable', 'Disable automatic certificate renewal. Default is to enable'
    end

    create_command 'enable-https' do |c|
      c.summary = 'Enable HTTPS'
      c.description = <<~DESC.chomp
        Enable HTTPS access to Alces Flight webservices.
      DESC
    end

    create_command 'disable-https' do |c|
      c.summary = 'Disable HTTPS'
      c.description = <<~DESC
        Disable HTTPS access to Alces Flight webservices.
        Some services will be available over HTTP whilst others will no longer be available.
      DESC
    end

    if Config::CACHE.development?
      create_command 'console' do |c|
        c.action do
          FlightCert::Command.new([], {}).instance_exec { binding.pry }
        end
      end
    end
  end
end
