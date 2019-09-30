ARG RUBY_VERSION=2.6.3-alpine3.9
# ------------------------------------------------------------------------------
# gems: install production gems only
# ------------------------------------------------------------------------------
FROM ruby:${RUBY_VERSION} as gems

COPY Gemfile Gemfile.lock ./

RUN apk add --update --no-cache --virtual .gem-deps \
  build-base \
  postgresql-dev \
  tzdata \
  && cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
  && gem install bundler -N --version "> 2" \
  && bundle install --without development test --jobs 4 --no-cache --retry 3 \
  && apk del --no-network .gem-deps \
  && rm -rf /root/.bundle/cache \
  && rm -rf /usr/local/bundle/cache \
  && find /usr/local/bundle/gems/ -name "*.c" -delete \
  && find /usr/local/bundle/gems/ -name "*.o" -delete \
  && find /usr/local/bundle/gems/ -path "*/docs*" -delete

# ------------------------------------------------------------------------------
# dev-and-test: install tools and gems used in dev and test
# ------------------------------------------------------------------------------
FROM ruby:${RUBY_VERSION} as dev-and-test

RUN apk add --update --no-cache \
  build-base \
  git \
  postgresql-dev \
  tzdata \
  && cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
  && gem install bundler -N --version "> 2"

WORKDIR /usr/src

COPY --from=gems /usr/local/bundle /usr/local/bundle

COPY Gemfile Gemfile.lock ./

RUN bundle --with development test --jobs 4 --no-cache --retry 3

COPY . .

CMD ["rails", "server", "-b", "0.0.0.0"]
