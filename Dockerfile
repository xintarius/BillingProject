FROM ruby:3.4.1-slim

ARG RAILS_ENV
ENV RAILS_ENV="${RAILS_ENV:-development}"
ENV BUNDLE_PATH="/usr/local/bundle"
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /rails

# Install system dependencies in one layer
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    libpq-dev \
    libvips42 \
    curl \
    gnupg \
    cron \
    nano \
    tzdata \
    netcat-openbsd \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    tesseract-ocr \
    tesseract-ocr-pol \
    imagemagick && \
  python3 -m venv /opt/venv && \
  /opt/venv/bin/pip install --no-cache-dir numpy opencv-python-headless && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Prepare app directories
RUN mkdir -p tmp/cache tmp/pids tmp/sockets && \
  chmod -R 777 tmp

# Copy Gemfile and install gems early (for cache)
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 4 --retry 3

# Copy the rest of the app
COPY . .

# Fix permissions
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails . && \
    chmod 777 /var/run

# Setup cron from whenever
RUN bundle exec whenever --update-crontab || true

# Add entrypoint
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

USER rails

EXPOSE 3000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
