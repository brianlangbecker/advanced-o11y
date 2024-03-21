# advanced-o11y

Specific environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io`
- `OTEL_EXPORTER_OTLP_HEADERS='x-honeycomb-team=api-key'`

If configuring non-prod API endpoint:

- `OTEL_EXPORTER_OTLP_ENDPOINT=https://api.some.place`
- `HONEYCOMB_API_ENDPOINT=https://api.some.place`

If using Classic Honeycomb, you'll also need a dataset and must include in the OTEL headers:

- `HONEYCOMB_DATASET` - The name of the dataset you want to write to
- `OTEL_EXPORTER_OTLP_HEADERS='x-honeycomb-team=api-key,x-honeycomb-dataset=year-service'`

## Running with Tilt

### Server apps
There is a `Tiltfile` to run these services on a local host using <https://tilt.dev/>.
After installing Tilt, running `tilt up` should spin up all of the services.

**NOTE**: you need to use tilt version 0.32.2+ otherwise you will get an error
```
Docker Compose service "frontend-java" has a relative build path: "./frontend"
```

This tiltfile utilizes [docker](https://docs.docker.com/desktop/install/mac-install/) and docker compose. You can verify they are installed first by checking `docker version` and `docker compose version` 

The default tilt setup runs the go services.

To run services:

```shell
tilt up 
```

When you're done:

```shell
tilt down
```
**NOTE**: if you only cancel the `tilt up` command, docker resources will remain running. If you then try to start up another set of services, you will get a port collision. `tilt down` removes any resources started by tilt previously.

List of supported languages

- `rb`


```shell
tilt up 
```

To configure a common set of services that are specific to ongoing development, or to override the default option of running all services in go, add a file `tilt_config.json` and specify a group or set of services.
This file is ignored by git so it can be developer specific and allows running `tilt up` without having to specify further arguments.


Example `tilt_config.json` to override go as the default service

```json
{
  "to-run": ["ruby"]
}
```

Example `tilt_config.json` to override the default with multiple services

```json
{
  "to-run": ["frontend-node", "message-go", "name-python", "year-rb"]
}
```

Once running, `curl localhost:6001/year` to get a greeting and a trace!

ctrl+c to kill the session, and `tilt down` to spin down all services.

### Client apps

To run the browser app inside of `/web` run

```shell
tilt up web node 
```

This will start up the browser app as well as all node backend services. The browser app makes requests to `http://localhost:6001/year` so there has to be a set of backend services running. It could also be any one of our other supported languages (e.g. `py`, `go` etc.)

## Running with Docker

You can also run services without Tilt by running docker-compose with the base configuration file and a language-specific configuration file.


```shell