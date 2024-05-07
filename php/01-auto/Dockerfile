# Dockerfile
FROM composer:latest

# Install Symfony CLI for local development
RUN curl -sS https://get.symfony.com/cli/installer | bash && mv /root/.symfony*/bin/symfony /usr/local/bin/symfony

# Install Symfony project dependencies
COPY . /app
WORKDIR /app

# Set command to run Symfony server
CMD ["symfony", "server:start", "--no-tls", "--port=6001", "--allow-http"]
