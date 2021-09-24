## Environment Modes

Flight Cert has three supported environment modes in which it can operate:
`production`, `standalone`, and `development`.

* `production`:  Used when installed via the OpenFlight repos.
* `standalone`:  Used for a manual installation intended for production.
* `development`: Used for a manual installation intended for development. 


### Production environment mode

This mode is automatically selected when Flight Cert is installed from the
OpenFlight repos.  The configuration file will be loaded from
`${flight_ROOT}/etc/cert.yaml`.  Any relative paths in the configuration file
are expanded from `${flight_ROOT}`.


### Standalone environment mode

This mode is to be used for a manual installation intended for production
usage.  The configuration file is loaded from a path relative to the Flight
Cert installation directory.  Any relative paths in the configuration file are
expanded from the Flight Cert installation directory.

For example, if the git repo was cloned to, say, `/opt/flight-cert`, the
configuration file would be loaded from `/opt/flight-cert/etc/cert.yaml` and,
the relative path for the `log_path` (`var/log/cert.log`) would be
expanded to `/opt/flight-cert/var/log/cert.log`.

There are three mechanisms by which standalone mode can be activated, any
of which is sufficient.

* Create the file `.flight-environment` containing the line
  `flight_ENVIRONMENT=standalone`.
  ```
  echo flight_ENVIRONMENT=standalone > .flight-environment
  ```
* Export the environment variable `flight_ENVIRONMENT` set to `standalone`.
  ```
  export flight_ENVIRONMENT=standalone
  ```
* Ensure that the `.flight-environment` file doesn't exist and that the
  `flight_ENVIRONMENT` variable isn't set.
  ```
  rm .flight-environment
  ```

### Development environment mode

This mode is to be used for a manual installation intended for development of
Flight Cert.  The configuration file is loaded from a path relative to the
Flight Cert installation directory.  Any relative paths in the configuration
file are expanded from the Flight Cert installation directory.

So if the git repo was cloned to, say, `/opt/flight-cert`, the configuration
file would be loaded from `/opt/flight-cert/etc/cert.yaml` and any relative
paths expanded from `/opt/flight-cert`.  E.g., by default the logs would
be written to `/opt/flight-cert/var/log/cert.log`.

There are two mechanisms by which development mode can be activated, either
of which is sufficient.

* Create the file `.flight-envionment` containing the line
  `flight_ENVIRONMENT=development`.
  ```
  echo flight_ENVIRONMENT=development > .flight-environment
  ```
* Export the environment variable `flight_ENVIRONMENT` set to `development`.
  ```
  export flight_ENVIRONMENT=development
  ```
