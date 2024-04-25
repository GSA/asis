ARG RUBY_VERSION=3.1.4
FROM public.ecr.aws/docker/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install -y build-essential libcurl4-openssl-dev curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle"

FROM base as build

RUN gem install bundler -v 2.4.7

COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash rails

RUN mkdir -p /rails/log /rails/tmp && \
    chown -R rails:rails /rails/log /rails/tmp

RUN bin/secure_docker

USER 1000:1000

EXPOSE 3300
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3300"]
