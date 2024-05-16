# Dockerfile
FROM php:latest

# Install Symfony CLI for local development
RUN curl -sS https://get.symfony.com/cli/installer | bash && mv /root/.symfony*/bin/symfony /usr/local/bin/symfony

COPY . /app
WORKDIR /app/year

# Set command to run Symfony server
CMD ["symfony", "server:start", "--no-tls", "--port=6001", "--allow-http"]
