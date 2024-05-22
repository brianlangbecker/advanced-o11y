# Academy Instrumentation Ruby

This project is a Ruby version of the Honeycomb.io Academy Instrumentation example. It sets up a simple Sinatra-based backend service with OpenTelemetry instrumentation and integrates with AWS S3 for image handling.

## Setup

### Prerequisites

- Ruby (preferably installed via a version manager like `rbenv` or `rvm`)
- Docker
- Git

### Configuration

These will be updated in the .env file discussed below

- HONEYCOMB_API_KEY: Your Honeycomb API key.
- BUCKET_NAME: The name of your S3 bucket containing images.
- OTEL_EXPORTER_OTLP_ENDPOINT: The OpenTelemetry collector endpoint.
- OTEL_EXPORTER_OTLP_HEADERS: Headers required for the OpenTelemetry collector.

### Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/yourusername/academy-instrumentation-ruby.git
   cd academy-instrumentation-ruby
   ```

2. **Set up the environment variables:**

   - Copy the example environment file and update it with your Honeycomb API key.

   ```sh
   cp .env.example .env
   # Edit .env to add your Honeycomb API key and other configuration
   ```

3. **Install the dependencies:**
   ```sh
   bundle install
   ```

### Run the app

`./run`

(This will run `docker compose` in daemon mode, and build containers.)

Access the app:

[http://localhost:8080]()

After making changes to a service, you can tell it to rebuild just that one:

`./run [ meminator | backend-for-frontend | image-picker | phrase-picker ]`

### Try it out

Visit [http://localhost:8080]()

Click the "GO" button. Then wait.

### Using Docker

To run the application using Docker, first ensure Docker is installed on your machine. Then you can build and run the application using Docker Compose:

```sh
docker-compose up --build
```
