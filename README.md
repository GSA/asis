OASIS Server
==============

[![Build Status](https://travis-ci.org/GSA/oasis.png)](https://travis-ci.org/GSA/oasis)
[![Code Climate](https://codeclimate.com/github/GSA/oasis.png)](https://codeclimate.com/github/GSA/oasis)

Federated image search across Flickr/Instagram/....

## Current Version

You are reading documentation for Oasis API v1.

## Contribute to the Code

The server code that runs the image search component of [DigitalGov Search](http://search.digitalgov.gov) is here on Github. If you're a Ruby developer, keep reading. Fork this repo to add features (such as additional datasets) or fix bugs.

### Ruby

This code is currently tested against [Ruby 2.1](http://www.ruby-lang.org/en/downloads/).

### Configuration

 1. Copy `instagram.yml.example` to `instagram.yml` and update the fields with your Instagram credentials.
 1. Copy `flickr.yml.example` to `flickr.yml` and update the fields with your Flickr credentials.

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

### ElasticSearch

We're using [ElasticSearch](http://www.elasticsearch.org/) (>= 1.3.0) for fulltext search. On a Mac, it's easy to install with [Homebrew](http://mxcl.github.com/homebrew/).

    $ brew install elasticsearch

Otherwise, follow the [instructions](http://www.elasticsearch.org/download/) to download and run it.


### Redis

Sidekiq (see below) uses Redis, so make sure you have that installed and running.

### Seed some image data

You can bootstrap the system with some government Flickr/Instagram profiles to see the system working.
Sample lists are in `config/instagram_profiles.csv` and `config/flickr_profiles.csv`.

    bundle exec rake oasis:seed_profiles
    
You can keep the indexes up to date by periodically refreshing the last day's images, perhaps via cron:
    
    bundle exec rake oasis:refresh

### Running it

Fire up a server and try it all out.

    bundle exec rails s

Here are the profiles you have just bootstrapped.

<http://localhost:3000/api/v1/instagram_profiles.json>

<http://localhost:3000/api/v1/flickr_profiles.json>

You can add a new profile manually via the REST API:

    	curl -XPOST "http://localhost:3000/api/v1/instagram_profiles.json?username=deptofdefense&id=542835249"
    	curl -XPOST "http://localhost:3000/api/v1/flickr_profiles.json?name=commercegov&id=61913304@N07&profile_type=user"

### Asynchronous job processing

We use [Sidekiq](http://sidekiq.org) for job processing. You can see all your Flickr and Instagram jobs queued up here:

<http://localhost:3000/sidekiq>

Kick off the indexing process:

    bundle exec sidekiq
    
In the Rails console, you can query each index manually using the Elasticsearch [Query DSL](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html):
    
    bin/rails c
    InstagramPhoto.count
    FlickrPhoto.count
    InstagramPhoto.all(query:{term:{username:'usinterior'}})
    FlickrPhoto.all(query:{term:{owner:'41555360@n03'}})

### Parameters

These parameters are accepted for the blended search API:

1. query
2. flickr_groups (comma separated)
2. flickr_users (comma separated)
2. instagram_profiles (comma separated)
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

### API Versioning

We support API versioning with the JSON format. The current version is v1. You can specify a specific JSON API version like this:

    curl http://localhost:3000/api/v1/image.json?flickr_groups=1058319@N21&flickr_users=35067687@n04,24662369@n07&instagram_profiles=nasa&query=earth

### Tests

These require an [ElasticSearch](http://www.elasticsearch.org/) server to be running.

    bundle exec rspec

### Code Coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/index.html`.

Click around on the files that have < 100% coverage to see what lines weren't exercised.

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA/oasis/issues).

-----

[Loren Siebert](https://github.com/loren) and [contributors](http://github.com/GSA/oasis/contributors).