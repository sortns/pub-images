FROM python:3.9.6-alpine3.14

LABEL maintainer="sortns@gmail.com"

RUN apk add --no-cache build-base
RUN apk --update --upgrade add gcc musl-dev jpeg-dev zlib-dev libffi-dev cairo-dev pango-dev gdk-pixbuf-dev curl

# install dependencies:
RUN pip3 install -Iv "requests>=2.31.0" "urllib3==2.0.3" "matplotlib==3.7.1"

