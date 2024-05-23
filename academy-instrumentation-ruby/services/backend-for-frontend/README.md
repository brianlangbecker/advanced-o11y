# Backend for Frontend

This Ruby service responds to `/createPicture` by gathering a random image and phrase, and then asking meminator to put them together.

## Setup

`bundle install`

## Run

No tracing will occur:

`ruby main.rb -o 0.0.0 -p 10114`

## Test

`curl localhost:10114`
