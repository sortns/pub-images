FROM fluent/fluentd:v1.16

# Use root account to use apk
USER root

# below RUN includes plugin as examples elasticsearch is not required
# you may customize including plugins as you wish
RUN apk add --no-cache --update --virtual .build-deps linux-headers \
    build-base ruby-dev \
    &&      gem install \
        fluent-plugin-multi-format-parser\
        fluent-plugin-mongo\
        fluent-plugin-kubernetes_metadata_filter\
    &&      gem sources --clear-all \
    &&     apk del .build-deps \
    &&     rm -rf /home/fluent/.gem/ruby/2.5.0/cache/*.gem

EXPOSE 9880/tcp

USER fluent