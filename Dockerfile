FROM ruby:3.4.7-alpine3.22
ARG BUNDLE_INSTALL_CMD

ENV S3_PUBLISHED_LOCATIONS_IPS_BUCKET 'stub-bucket'
ENV S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY 'stub-key'

WORKDIR /usr/src/app


COPY Gemfile Gemfile.lock .ruby-version ./


RUN apk --no-cache add --virtual .build-deps build-base && \
    apk --no-cache add mysql-dev && \
    ${BUNDLE_INSTALL_CMD} && \
    apk del .build-deps

COPY . .


COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["bundle", "exec", "puma", "-p", "8080", "--quiet", "--threads", "8:32"]
