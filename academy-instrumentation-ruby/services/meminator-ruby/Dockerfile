# Use the official Ruby image from the Docker Hub
FROM ruby:3.0

# Set the working directory inside the container
WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y imagemagick && \
    rm -rf /var/lib/apt/lists/*

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install the Ruby dependencies
RUN bundle install

# Copy the rest of the application code into the container
COPY . .

# Expose the port that the app runs on
EXPOSE 10114

# Set the command to run the app
CMD ["ruby", "main.rb", "-o", "0.0.0.0", "-p", "10114"]
