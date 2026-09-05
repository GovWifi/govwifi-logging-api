FROM ruby:3.4.9-alpine3.22
ARG BUNDLE_WITHOUT

ENV S3_PUBLISHED_LOCATIONS_IPS_BUCKET 'stub-bucket'
ENV S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY 'stub-key'

WORKDIR /usr/src/app


COPY Gemfile Gemfile.lock .ruby-version ./
RUN apk --no-cache add --virtual .build-deps build-base && \
    apk --no-cache add mysql-dev && \
    bundle install --jobs 1 --retry 5 && \
    apk del .build-deps
RUN if [ "${BUNDLE_WITHOUT}" = "development test" ]; then \
        echo 'BUNDLE_WITHOUT: "development:test"' > /usr/local/bundle/config; \
        bundle clean --force; \
      fi

COPY . .


COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["bundle", "exec", "puma", "-p", "8080", "--quiet", "--threads", "8:32"]
