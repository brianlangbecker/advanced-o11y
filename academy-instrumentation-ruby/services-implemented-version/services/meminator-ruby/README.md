# Phrase Picker

This Ruby service supplies random phrases.

## setup

`brew install imagemagick` for Mac
`bundle install`

## Run

No tracing will occur:

`ruby main.rb -o 0.0.0 -p 10114`

## Test

`curl localhost:10114/applyPhraseToPicture -d '{"phrase":"Yo Yo Yo!", "imageUrl":"https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Banana-Single.jpg/1360px-Banana-Single.jpg"}' -H "Content-Type: application/json" -X POST > out.jpg`
