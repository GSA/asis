ASIS Server
==============

[![CircleCI](https://circleci.com/gh/GSA/asis.svg?style=shield)](https://circleci.com/gh/GSA/asis)
[![Code Climate](https://codeclimate.com/github/GSA/asis/badges/gpa.svg)](https://codeclimate.com/github/GSA/asis)
[![Test Coverage](https://codeclimate.com/github/GSA/asis/badges/coverage.svg)](https://codeclimate.com/github/GSA/asis)

ASIS (Advanced Social Image Search) indexes Flickr and Instagram images and provides a search API across both indexes.

## Current version

You are reading documentation for ASIS API v1.

## Contribute to the code

The server code that runs the image search component of [Search.gov](https://search.gov/) is here on Github.
[Fork this repo](https://github.com/GSA/oasis/fork) to add features like additional datasets, or to fix bugs.

## Deprecation Warning: Instagram
The Instagram features have been deprecated. Documentation and examples remain for clarity pending code and spec cleanup.

## Dependencies

### Ruby

Use [rvm](https://rvm.io/) to install the version of Ruby specified in `.ruby-version`.

### Configuration

 1. Copy `config/instagram.yml.example` to `config/instagram.yml` and update the fields with your Instagram credentials.
 1. Copy `config/flickr.yml.example` to `config/flickr.yml` and update the fields with your Flickr credentials.

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

### Elasticsearch

We're using [Elasticsearch](http://www.elasticsearch.org/) (>= 6.8) for fulltext search.

Install [Docker](https://www.docker.com/products/docker-desktop) if you haven't done so yet. Once you have Docker installed on your machine, run the following command from the project root:

    docker-compose up elasticsearch

Verify that Elasticsearch 6.8.x is running on port 9200:

```
$ curl localhost:9200
{
  "name" : "wp9TsCe",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "WGf_peYTTZarT49AtEgc3g",
  "version" : {
    "number" : "6.8.9",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "c63e621",
    "build_date" : "2020-02-26T14:38:01.193138Z",
    "build_snapshot" : false,
    "lucene_version" : "7.7.2",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### Kibana

[Kibana](https://www.elastic.co/kibana) is not required, but it can very helpful for debugging your Elasticsearch cluster or data.
You can also run Kibana using Docker:

    docker-compose up kibana

Verify that you can access Kibana in your browser: [http://localhost:5601/](http://localhost:5601/)

### Redis

Sidekiq (see below) uses [Redis](http://redis.io), so make sure you have that installed and running. You can install it it from the [Redis website](https://redis.io/download), or run it using Docker:

    docker-compose up redis

To run Elasticsearch, Kibana, and Redis, you can simply run:

    docker-compose up

## Development/Usage

### Seed some image data

You can bootstrap the system with some government Flickr/Instagram profiles and MRSS feeds to see the system working.
Sample lists are in `config/instagram_profiles.csv` and `config/flickr_profiles.csv` and `config/mrss_profiles.csv`.

    bundle exec rake oasis:seed_profiles

You can keep the indexes up to date by periodically refreshing the last day's images. To do this manually via the Rails console:

    MrssPhotosImporter.refresh
    FlickrPhotosImporter.refresh
    InstagramPhotosImporter.refresh

### Running it

Fire up a server and try it all out.

    bundle exec rails s

Here are the profiles you have just bootstrapped. Note: Chrome does a nice job of pretty-printing the JSON response.

<http://localhost:3000/api/v1/instagram_profiles.json>

<http://localhost:3000/api/v1/flickr_profiles.json>

<http://localhost:3000/api/v1/mrss_profiles.json>

You can add a new profile manually via the REST API:

        curl -XPOST "http://localhost:3000/api/v1/instagram_profiles.json?username=deptofdefense&id=542835249"
        curl -XPOST "http://localhost:3000/api/v1/flickr_profiles.json?name=commercegov&id=61913304@N07&profile_type=user"
        curl -XPOST "http://localhost:3000/api/v1/mrss_profiles.json?url=https://share-ng.sandia.gov/news/resources/news_releases/feed/"

MRSS profiles work a little differently than Flickr and Instagram profiles. When you create the MRSS profile, Oasis assigns a
short name to it that you will use when performing searches. The JSON result from the POST request will look something like this:

      {
        "created_at": "2014-10-26T18:25:21.167+00:00",
        "updated_at": "2014-10-26T18:25:21.173+00:00",
        "name": "72",
        "id": "https://share-ng.sandia.gov/news/resources/news_releases/feed/"
      }

### Asynchronous job processing

We use [Sidekiq](http://sidekiq.org) for job processing. You can see all your Flickr and Instagram jobs queued up here:

<http://localhost:3000/sidekiq>

Kick off the indexing process:

    bundle exec sidekiq

### Searching

In the Rails console, you can query each index manually using the Elasticsearch [Query DSL](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html):

    bin/rails c
    InstagramPhoto.count
    FlickrPhoto.count
    MrssPhoto.count
    InstagramPhoto.all(query:{term:{username:'usinterior'}}).results
    FlickrPhoto.all(query:{term:{owner:'28634332@N05'}}).results
    MrssPhoto.all(query:{match:{description:'air'}}).results

### Parameters

These parameters are accepted for the blended search API:

1. query
2. flickr_groups (comma separated)
2. flickr_users (comma separated)
2. instagram_profiles (comma separated)
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

* `type`: FlickrPhoto | InstagramPhoto
* `title`
* `url`
* `thumbnail_url`
* `taken_at`

### API versioning

We support API versioning with the JSON format. The current version is v1. You can specify a specific JSON API version like this:

    curl "http://localhost:3000/api/v1/image.json?flickr_groups=1058319@N21&flickr_users=35067687@n04,24662369@n07&instagram_profiles=nasa&mrss_names=72,73&query=earth"

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
