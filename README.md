# advanced-o11y

Welcome to the Advanced o11y Ruby demo. Here are some information of how to run it.

In order to run this demo, you need to set certain environment variables in your environment.

Here are the specific environment variables:

- `OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io`
- `OTEL_EXPORTER_OTLP_HEADERS='x-honeycomb-team=api-key'`

If configuring non-prod API endpoint:

- `OTEL_EXPORTER_OTLP_ENDPOINT=https://api.some.place`
- `HONEYCOMB_API_ENDPOINT=https://api.some.place`

If using Classic Honeycomb, you'll also need a dataset and must include in the OTEL headers:

- `HONEYCOMB_DATASET` - The name of the dataset you want to write to
- `OTEL_EXPORTER_OTLP_HEADERS='x-honeycomb-team=api-key,x-honeycomb-dataset=year-service'`

If using Honeycomb Beeline, which is Honeycomb's library to send telemetry easily to Honeycome, the following environments are required:

- `HONEYCOMB_API_KEY=api-key`
- `HONEYCOMB_API_ENDPOINT=https://api.honeycomb.io`
- `SERVICE_NAME` - The name of the service you want to write to
- `HONEYCOMB_DATASET` - The name of the dataset you want to write to (usually same as service name)

## Required Softwares

### Docker Desktop and Kubernetes
In order to run this demo, you may need to install `Docker Desktop` and have its `Kubernetes` enabled. Installing Docker Desktop can be found [here](https://www.docker.com/products/docker-desktop/).

After the installation, go to the settings (gear icon at the top of Docker Desktop), and select Kubernetes on the left pane menu. Then, check `Enable Kubernetes`. The installation may take a few minutes.

## Running with Tilt

Under the directory `ruby`, you will find a series of directories. Please refer to the table below to understand what they are and how to use it.

|Directory|Entrypoint (curl)|What it is|
|---|---|---|
|01-manual|`curl http://localhost:6001/year`|Year service without any instrumentation|
|01-start-manual|`curl http://localhost:6001/year`|Year service having OTEL instrumentation|
|02-_start_asynchronous|`curl http://localhost:6001/year`|Year service with async. child worker|
|03-span-events|`curl http://localhost:6001/year`|Year service having span events|
|04-span-links|`curl http://localhost:6001/year`|Year service having span events|
|05-propagation|`curl http://localhost:8000/name`|Name service with year service, without propagation|
|05-start-propagation|`curl http://localhost:8000/name`|Name service with year service, with propagation|
|ruby-greeting-services|`curl http://localhost:6001/year`|Year service with o11y wrapper|

### Server apps
In each directories, there is a `Tiltfile` to run these services on a local host using <https://tilt.dev/>.
After installing Tilt, you may go into each directories and running the command `tilt up` should spin up the necessary service.

**NOTE**: you need to use tilt version 0.32.2+ otherwise you will get an error

```
tilt version
v0.33.11, built 2024-02-15
```

This tiltfile utilizes [docker](https://docs.docker.com/desktop/install/mac-install/) and docker compose. You can verify they are installed first by checking `docker version` and `docker compose version`

```
docker compose version
Docker Compose version v2.24.6-desktop.1
```

The default tilt setup runs the `year-service` service.

To run services:

```shell
tilt up 
```

**NOTE**: Pressing `space` key will open up the browser having the tilt ui. You can monitor the service's status conveniently using it.

When you're done, run the following command from the same directory where you ran tile up:

```shell
tilt down
```
**NOTE**: if you only cancel the `tilt up` command, or click `Ctrl+c` to exit, docker resources will remain running. If you then try to start up another set of services, **_you will get a port collision_**. Running `tilt down` removes any resources started by tilt previously. You can also stop and remove any previously running containers via docker desktop as needed.

List of supported languages

- `rb` (ruby)

### Configuring a common set of services

To configure a common set of services that are specific to ongoing development, or to override the default option of running all services, add a file `tilt_config.json` and specify a group or set of services.
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

### Invoking `year` service

Once the service is running, run the following command to get a greeting and a trace!

```
curl localhost:6001/year
2018%
```

You can run it several times to see a random print of year from this year service.

Press ctrl+c to kill the session, and `tilt down` to spin down all services.

## Running with Docker

You can also run services without Tilt by running docker-compose with the base configuration file and a language-specific configuration file.


```shell