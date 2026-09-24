FROM ruby:4.0-alpine3.24
ARG BUNDLE_INSTALL_CMD

ENV S3_PUBLISHED_LOCATIONS_IPS_BUCKET 'stub-bucket'
ENV S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY 'stub-key'
ENV MARIADB_TLS_DISABLE_PEER_VERIFICATION=1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock .ruby-version ./

RUN if [ -n "${BUNDLE_WITHOUT}" ]; then \
        bundle config set without "${BUNDLE_WITHOUT}"; \
      fi && \
    apk --no-cache add --virtual .build-deps build-base && \
    apk --no-cache add mysql-dev && \
    bundle install --jobs 1 --retry 5 && \
    apk del .build-deps

COPY . .

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-p", "8080", "--quiet", "--threads", "8:32"]
