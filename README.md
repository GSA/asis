ASIS Server
==============

[![CircleCI](https://circleci.com/gh/GSA/asis.svg?style=shield)](https://circleci.com/gh/GSA/asis)
[![Code Climate](https://codeclimate.com/github/GSA/asis/badges/gpa.svg)](https://codeclimate.com/github/GSA/asis)
[![Test Coverage](https://codeclimate.com/github/GSA/asis/badges/coverage.svg)](https://codeclimate.com/github/GSA/asis)

ASIS (Advanced Social Image Search) indexes Flickr and MRSS images and provides a search API across both indexes.

## Current version

You are reading documentation for ASIS API v1.

## Contribute to the code

The server code that runs the image search component of [Search.gov](https://search.gov/) is here on Github.
[Fork this repo](https://github.com/GSA/oasis/fork) to add features like additional datasets, or to fix bugs.

## Dependencies

### Ruby

Use [rvm](https://rvm.io/) to install the version of Ruby specified in `.ruby-version`.

### Configuration

 1. Copy `config/flickr.yml.example` to `config/flickr.yml` and update the fields with your Flickr credentials.

### Docker

Docker can be used to: 1) run just the required services (MySQL, Elasticsearch, etc.) while [running the asis application in your local machine](https://github.com/GSA/asis#developmentusage), and/or 2) run the entire `asis` application in a Docker container.  Please refer to [searchgov-services](https://github.com/GSA/search-services) for detailed instructions on centralized configuration for the services.

When running in a Docker container (option 2 above), the `asis` application is configured to run on port [3300](http://localhost:3300/). Required dependencies - ([Ruby](https://github.com/GSA/asis#ruby), and [Gems](https://github.com/GSA/asis#ruby)) - are installed using Docker. However, other data or configuration may need to be setup manually, which can be done in the running container using `bash`.

Any operations (using rails console, running rake commands, etc.) on ASIS application running in Docker container can be performed by executing below command in `search-services`.

    $ docker compose run asis bash

For example, to setup DB in Docker:

    $ docker compose run asis bash
    $ bin/rails oasis:seed_profiles

The Elasticsearch service provided by `searchgov-services` is configured to run on the default port, [9200](http://localhost:9200/). To use a different host (with or without port) or set of hosts, set the `ES_HOSTS` environment variable. For example, use following command to run the specs using Elasticsearch running on `localhost:9207`:

    ES_HOSTS=localhost:9207 bundle exec rspec spec

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

## Development/Usage

### Seed some image data

You can bootstrap the system with some government Flickr profiles and MRSS feeds to see the system working.
Sample lists are in config/flickr_profiles.csv` and `config/mrss_profiles.csv`.

    bundle exec rake oasis:seed_profiles

You can keep the indexes up to date by periodically refreshing the last day's images. To do this manually via the Rails console:

    MrssPhotosImporter.refresh
    FlickrPhotosImporter.refresh

### Running it

Fire up a server and try it all out.

    bundle exec rails s

Here are the profiles you have just bootstrapped. Note: Chrome does a nice job of pretty-printing the JSON response.

<http://localhost:3000/api/v1/flickr_profiles.json>

<http://localhost:3000/api/v1/mrss_profiles.json>

You can add a new profile manually via the REST API:

        curl -XPOST "http://localhost:3000/api/v1/flickr_profiles.json?name=commercegov&id=61913304@N07&profile_type=user"
        curl -XPOST "http://localhost:3000/api/v1/mrss_profiles.json?url=https://share-ng.sandia.gov/news/resources/news_releases/feed/"

MRSS profiles work a little differently than Flickr profiles. When you create the MRSS profile, Oasis assigns a
short name to it that you will use when performing searches. The JSON result from the POST request will look something like this:

      {
        "created_at": "2014-10-26T18:25:21.167+00:00",
        "updated_at": "2014-10-26T18:25:21.173+00:00",
        "name": "72",
        "id": "https://share-ng.sandia.gov/news/resources/news_releases/feed/"
      }

### Asynchronous job processing

We use [Sidekiq](http://sidekiq.org) for job processing. You can see all your jobs queued up here:

<http://localhost:3000/sidekiq>

Kick off the indexing process:

    bundle exec sidekiq

### Searching

In the Rails console, you can query each index manually using the Elasticsearch [Query DSL](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html):

    bin/rails c
    FlickrPhoto.count
    MrssPhoto.count
    FlickrPhoto.all(query:{term:{owner:'28634332@N05'}}).results
    MrssPhoto.all(query:{match:{description:'air'}}).results

### Parameters

These parameters are accepted for the blended search API:

1. query
2. flickr_groups (comma separated)
2. flickr_users (comma separated)
2. mrss_names (comma separated list of Oasis-assigned names)
4. size
5. from

### Results

The top level JSON contains these fields:

* `total`
* `offset`
* `suggestion`: The overridden spelling suggestion
* `results`

Each result contains these fields:

* `type`: FlickrPhoto
* `title`
* `url`
* `thumbnail_url`
* `taken_at`

### API versioning

We support API versioning with the JSON format. The current version is v1. You can specify a specific JSON API version like this:

    curl "http://localhost:3000/api/v1/image.json?flickr_groups=1058319@N21&flickr_users=35067687@n04,24662369@n07&mrss_names=72,73&query=earth"

## Tests

These require an [Elasticsearch](http://www.elasticsearch.org/) server and [Redis](http://redis.io) server to be running.

    bundle exec rspec

### Code coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/index.html`.

Click around on the files that have < 100% coverage to see what lines weren't exercised.

### Code Quality

We use [Rubocop](https://rubocop.org/) for static code analysis. Settings specific to ASIS are configured via [.rubocop.yml](.rubocop.yml). Settings that can be shared among all Search.gov repos should be configured via the [searchgov_style](https://github.com/GSA/searchgov_style) gem.

## Code samples

We "eat our own dog food" and use this ASIS API to display image results on the government websites that use [Search.gov](https://search.gov/).

See the results for a search for [*bird* on FWS.gov](https://search.usa.gov/search/images?affiliate=fws.gov&query=bird).

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA/oasis/issues).

-----

[Loren Siebert](https://github.com/loren) and [contributors](http://github.com/GSA/oasis/contributors).
