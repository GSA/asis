FROM ruby:3.0.6
WORKDIR /usr/src/app
EXPOSE 3000

ENV OPENSSL_CONF /etc/ssl/

RUN apt install -y curl \
  && gem install bundler:2.4.7 

COPY Gemfile* /usr/src/app/
ENV BUNDLE_PATH /gems
RUN bundle install

COPY . /usr/src/app/
