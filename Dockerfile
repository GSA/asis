FROM ruby:3.0.6
WORKDIR /usr/src/app
EXPOSE 3000

RUN apt install -y curl

COPY Gemfile* /usr/src/app/
ENV BUNDLE_PATH /gems
RUN bundle install

COPY . /usr/src/app/
CMD ["rails", "server", "-b", "0.0.0.0"]
