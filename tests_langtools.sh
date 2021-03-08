#! /bin/bash

# First, make sure that you have a lt server runnning:
# https://dev.languagetool.org/http-server

# Good link:
# https://languagetool.org/http-api/swagger-ui/#!/default/post_check

# curl -X POST --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' -d 'text=edfhdfhdf&language=en-US&enabledOnly=false' 'https://api.languagetoolplus.com/v2/check'

LT_HOST="http://localhost:8081/v2/check"

function post_text {
  local text="$1"
  echo $(curl -X POST --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' -d "text=${text}&language=en-US&enabledOnly=false" "$LT_HOST")
}

echo $(post_text "I like to eatt sandwich")
