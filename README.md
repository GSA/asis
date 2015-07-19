ASIS Server
==============

[![Build Status](https://travis-ci.org/GSA/asis.png)](https://travis-ci.org/GSA/asis)
[![Code Climate](https://codeclimate.com/github/GSA/oasis.png)](https://codeclimate.com/github/GSA/oasis)

ASIS (Advanced Social Image Search) indexes Flickr and Instagram images and provides a search API across both indexes.

## Current version

You are reading documentation for ASIS API v1.

## Contribute to the code

The server code that runs the image search component of [DigitalGov Search](http://search.digitalgov.gov) is here on Github. 
[Fork this repo](https://github.com/GSA/oasis/fork) to add features like additional datasets, or to fix bugs.

### Ruby

This code is currently tested against [Ruby 2.1](http://www.ruby-lang.org/en/downloads/).

### Configuration

 1. Copy `instagram.yml.example` to `instagram.yml` and update the fields with your Instagram credentials.
 1. Copy `flickr.yml.example` to `flickr.yml` and update the fields with your Flickr credentials.

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

### Elasticsearch

We're using [Elasticsearch](http://www.elasticsearch.org/) (>= 1.7.0) for fulltext search. On a Mac, it's easy to 
install with [Homebrew](http://mxcl.github.com/homebrew/).

    $ brew install elasticsearch

Otherwise, follow the [instructions](http://www.elasticsearch.org/download/) to download and run it.

You can generally leave the defaults in elasticsearch.yml as they are, but there are two exceptions:

#### Enable dynamic scripting

[Dynamic scripting](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/modules-scripting.html#_enabling_dynamic_scripting) is disabled by default since Elasticsearch 1.2.0. You can either set it to `false` or use the safer setting of `sandbox`:

    script.disable_dynamic: sandbox

#### Number of shards

Default shards are set to 5, but you'll have an easier time with tests if you set it to 1 on your development machine:

    index.number_of_shards: 1
 
### Redis

Sidekiq (see below) uses [Redis](http://redis.io), so make sure you have that installed and running.

### Seed some image data

You can bootstrap the system with some government Flickr/Instagram profiles and MRSS feeds to see the system working.
Sample lists are in `config/instagram_profiles.csv` and `config/flickr_profiles.csv` and `config/mrss_profiles.csv`.

    bundle exec rake oasis:seed_profiles
    
You can keep the indexes up to date by periodically refreshing the last day's images. To do this manually via the Rails console:
  
    FlickrPhotosImporter.refresh
    InstagramPhotosImporter.refresh
    MrssPhotosImporter.refresh

The Capistrano deploy script has [whenever](https://github.com/javan/whenever) hooks so this refresh happens automatically 
via cron in your production environment.

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
    	curl -XPOST "http://localhost:3000/api/v1/mrss_profiles.json?url=http%3A%2F%2Fremotesensing.usgs.gov%2Fgallery%2Frss.php%3Fcat%3Dall"
    	
MRSS profiles work a little differently than Flickr and Instagram profiles. When you create the MRSS profile, Oasis assigns a
short name to it that you will use when performing searches. The JSON result from the POST request will look something like this:

      {
        "created_at": "2014-10-26T18:25:21.167+00:00",
        "updated_at": "2014-10-26T18:25:21.173+00:00",
        "name": "72",
        "id": "http:\/\/remotesensing.usgs.gov\/gallery\/rss.php?cat=all"
      }

### Asynchronous job processing

We use [Sidekiq](http://sidekiq.org) for job processing. You can see all your Flickr and Instagram jobs queued up here:

<http://localhost:3000/sidekiq>

Kick off the indexing process:

    bundle exec sidekiq
    
In the Rails console, you can query each index manually using the Elasticsearch [Query DSL](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html):
    
    bin/rails c
    InstagramPhoto.count
    FlickrPhoto.count
    MrssPhoto.count
    InstagramPhoto.all(query:{term:{username:'usinterior'}})
    FlickrPhoto.all(query:{term:{owner:'41555360@n03'}})
    MrssPhoto.all(query:{term:{mrss_url:'http://remotesensing.usgs.gov/gallery/rss.php?cat=all'}})

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

### Tests

These require an [Elasticsearch](http://www.elasticsearch.org/) server and [Redis](http://redis.io) server to be running.

    bundle exec rspec

### Code coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/index.html`.

Click around on the files that have < 100% coverage to see what lines weren't exercised.

## Code samples

We "eat our own dog food" and use this ASIS API to display image results on the government websites that use [DigitalGov Search](http://search.digitalgov.gov).

See the sample results below for a search for [*moon* on DOI.gov](http://search.doi.gov/search/images?affiliate=doi.gov&query=moon).

[![DOI ASIS-powered results for moon](https://9fddeb862c037f6d2190-f1564c64756a8cfee25b6b19953b1d23.ssl.cf2.rackcdn.com/release-08-2014-doi-instagram.png "DOI ASIS-powered results for moon")](http://search.doi.gov/search/images?&affiliate=doi.gov&query=moon)

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA/oasis/issues).

-----

[Loren Siebert](https://github.com/loren) and [contributors](http://github.com/GSA/oasis/contributors).
