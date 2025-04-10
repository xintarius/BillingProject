FROM ruby:3.4.1-slim

ARG RAILS_ENV
ARG SECRET_KEY_BASE
ARG DATABASE_NAME
ARG DATABASE_HOST
ARG DATABASE_USERNAME
ARG DATABASE_OPTION
ARG DATABASE_PASSWORD
ARG ENDPOINT
ARG SECRET_ACCES_KEY
ARG REGION
ARG DEFAULT_BUCKET
ARG SENTRY_DSN

WORKDIR /rails

# install dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential git pkg-config libpq-dev libvips42 curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle"

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install

COPY . .

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails .

USER 1000:1000

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]