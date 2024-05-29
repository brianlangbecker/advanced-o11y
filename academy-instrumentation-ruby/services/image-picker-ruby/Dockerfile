# Use the official Ruby image from the Docker Hub
FROM ruby:3.0

# Set the working directory inside the container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the container
COPY Gemfile Gemfile.lock ./

# Install the dependencies
RUN bundle install

# Copy the rest of the application code into the container
COPY . .

# Expose the port that the app runs on
EXPOSE 10114

# Set the command to run the app
CMD ["ruby", "server.rb", "-o", "0.0.0.0", "-p", "10114"]
