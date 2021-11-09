# Flight Cert

Manage the HTTPS server and SSL certificates.

## Overview

Flight Cert facilitates managing SSL certificates and configuring a web server
to use the certificates.

## Installation

### Installing with the OpenFlight package repos

Flight Cert is available as part of the *Flight Web Suite*.  This is the
easiest method for installing Flight Cert and all its dependencies.  It is
documented in [the OpenFlight
Documentation](https://use.openflighthpc.org/installing-web-suite/install.html#installing-flight-web-suite).

### Manual Installation

#### Prerequisites

Flight Cert is developed and tested with Ruby version `2.7.1` and `bundler`
`2.1.4`.  Other versions may work but currently are not officially supported.

#### Install Flight Cert

The following will install from source using `git`.  The `master` branch is
the current development version and may not be appropriate for a production
installation. Instead a tagged version should be checked out.

```
git clone https://github.com/alces-flight/flight-cert.git
cd flight-cert
git checkout <tag>
bundle config set --local with default
bundle config set --local without development
bundle install
```

The manual installation of Flight Cert comes preconfigured to run in
development mode.  If installing Flight Cert manually for production usage you
will want to follow the instructions to [set the environment
mode](/docs/environment-modes.md) to `standalone`.

Use the script located at `bin/cert` to execute the tool.

## Configuration

Flight Cert requires configuring before it can be used.

To use Flight Cert to create Let's Encrypt SSL certificates, you will need to
configure `certbot_bin` and `certbot_plugin_flags`.

To use Flight Cert to automate the renewal of Let's Encrypt certificates, you
will need to configure `cron_path` and `cron_script`.

To use Flight Cert to manage a web servers HTTPS configuration, you will need
to configure `https_enable_paths`, `status_command`, `restart_command` and
`start_command_prompt`.

Details of how to configure these settings can be found in the [configuration
file](etc/cert.yaml).

### Environment Modes

If Flight Cert has been installed manually for production usage you
will want to follow the instructions to [set the environment
mode](docs/environment-modes.md) to `standalone`.

## Operation

Generate and use self-signed SSL certificates:

```
bin/cert cert-gen --domain <DOMAIN> --cert-type self_signed
bin/cert enable-https
```

Generate and use Let's Encrypt SSL certificates:

```
bin/cert cert-gen --domain <DOMAIN> --cert-type lets_encrypt --email <EMAIL>
bin/cert enable-https
```

Use self generated certificates:

```
bin/cert cert-install --key <PATH-TO-PRIVKEY> --fullchain <PATH-TO-FULLCHAIN>
bin/cert enable-https
```

Disable HTTPS usage:

```
bin/cert disable-https
```

Configure automatic renewal of Let's Encrypt certificates:

```
bin/cert cron-renewal
```

Disable automatic renewal of Let's Encrypt certificates:

```
bin/cert cron-renewal --disable
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

FlightCert is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
