# 🐳 Reach Digital Magento 2 Docker+local hybrid development environment. 🐳

Docker for services, php locally. No sync, no mental overhead, not performance
penalties.  
`php`, `nginx`, `https`, `http/2`, `varnish`, `mysql` `elasticsearch`,
`rabbitmq`, `mailhog`

## Reasoning

Docker is easy, docker scales, we love docker, but docker's volume mounting is
slow, we can't have slow.

The problem with all the docker devboxes is that they require running php inside
a vm. The problem with php in a vm is that files need to be available in the vm,
but it also also need to have files outside the vm, because programs like
PHPStorm and others do not accept network drives.

Sync is slower than no sync. [docker-sync](http://docker-sync.io/),
[nfs](https://docs.docker.com/v17.12/datacenter/dtr/2.1/guides/configure/use-nfs/),
[unison](https://www.cis.upenn.edu/~bcpierce/unison/),
[mutagen](https://mutagen.io/) offer good sync solutions, but always slower than
no sync.

Also syncs require additional HDD space and additional mental overhead: Are my
files synced?, Is my sync broken? Are there sync conflicts? Why did that file
appear here? Where should I execute my php cli scripts? Where should I run node
cli? Why is my system slow? Sync is bad.

## Goals

- It should be possible for a frontend developer without any backend skillsto
  set up a development environment.
- It should be possible for a backend developer to add or upgrade services.
- It should be possible for a backend developer to propagate the changes to the
  rest of the team with version control.

## Principles

- No magic: As few CLI tools that will automatically 'fix' things. Do not use
  wrappers around existing tools: docker / etc. Exception: php runs locally,
  needs to be set up.
- Declarative: Developer should define the final state instead of running
  upgrade scripts (hence, docker).
- Minimal: Use as few cpu cycles and memory as possible.

## Global installation (only once)

### Cleanup your system

Since we're running some things locally it probably is a good time to clean some
stuff up.

Run `brew doctor` and make sure you don't have errors.

You should not have any services running like.

- `php`: find them with `brew list | grep php`, uninstall them.
- `httpd`: disable apache with something like
  https://apple.stackexchange.com/questions/119674/disable-apache-autostart/119678
- `mysql`: uninstall or disable mysql, or at least make sure it doesnt run on
  the default MySQL port.
- `nginx`: uninstall

Take a look at `./bash_profile` and make sure it doesn't contain any references
to `/usr/local/Cellar/php*`.

### Installing services

Since we're running a hybrid docker+local system we need to set up PHP to run
locally.

```bash
# Cleans (destructively) + installs php on OSX!
curl -s https://raw.githubusercontent.com/ho-nl/docker-development-box/master/install.sh?token=AAJP2AECWY7UWCOGGX7EDS26LEH4G | bash -s -- -i
# Save the `🐞  Xdebug path: ...` somewhere to setup xdebug in PHPStorm.
```

It will (re)install multiple php-fpm services, one for each version (port: 9072,
9073, 9074) and one for each version with xdebug (port: 9172, 9173, 9174).

#### Switch PHP versions

```bash
brew unlink php@7.3
brew link php@7.2 --force
php -v
```

Should now show the right version. If it doesn't there might be still be a
version linked or your ~/.bash_profile should be cleaned up.

[auto switcher](https://github.com/ho-nl/docker-development-box/issues/12)

### Install docker

1. Install [docker for mac](https://docs.docker.com/docker-for-mac/).
2. Exclude `~/Library/Containers` from your backups
3. `brew install ctop`: `htop` for docker.

### Install local certificate

Add
[vendor/reach-digital/docker-devbox/hitch/\*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem)
to your OSX keychain.

## Project installation

- Install this in the project `composer require reach-digital/docker-devbox`
- Install `static-content-deploy`
  [patches](https://github.com/ho-nl/magento2-ReachDigital_Patches).
- Disable services you don't need in `docker-compose.yml` (required: `hitch`,
  `varnish`, `nginx` and `db`).
- Commit the `docker-compose.yml` file to prevent future accidental changes.

## Usage

- Start: `docker-compose up -d`
- Logging: `ctop`
- Stop: `docker-compose down`

**Delete data (mysql/elasticsearch):**

- `rm -rf var/.esdata`
- `rm -rf var/.mysqldata`

### Settings for `mysql` `elasticsearch`, `rabbitmq`, `mailhog`

### Setup xdebug

- Web: Xdebug should work by default when you have the
  [Xdebug helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)
  installed + PHPStorm is listening to connections.
- Cli: Use
  `XDEBUG_CONFIG="" php -c /usr/local/etc/php/7.2/php-xdebug.ini bin/magento`
- Tests: Create a local interpreter, the PHP version you're looking for should
  be suggested and add the `🐞 Xdebug path:` to enable xdebug (you should have
  seen that with the installation).

### Setup cron

[default setup](https://devdocs.magento.com/guides/v2.3/config-guide/cli/config-cli-subcommands-cron.html#create-the-magento-crontab)

## FAQ?

### Where can I find logs?

- For all other services, start `ctop` and press `<-` on your keyboard.
- phplogs: tail -f /usr/local/var/log/php\* (will probably be empty as it will
  only output true errors)

### How do I set up https?

https _only_ with [hitch](https://github.com/varnish/hitch)

```
bin/magento config:set --lock-env web/unsecure/base_url https://blabla.localhost.reachdigital.io/
bin/magento config:set --lock-env web/secure/base_url https://blabla.localhost.reachdigital.io/
# You can use any domain that points to 127.0.0.1, you can't use https://localhost because Magento can't handle that.
# *.localhost.reachdigital.io always resolves to 127.0.0.1
```

The docker container does _not_ support http, _only_ https.

### How do I set up Varnish?

Cache by default with https://www.varnish-software.com/

```
bin/magento setup:config:set --http-cache-hosts=127.0.0.1:6081
bin/magento config:set --lock-config system/full_page_cache/caching_application 2
```

- You can use `bin/magento cache:clean` or `cache:flush` to flush Varnish.
- You can use `CMD+SHIFT+R` to bypass Varnish for any page.

### How do I set up Redis?

```
php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-db=0 --cache-backend-redis-port=6379
php bin/magento setup:config:set --session-save=redis --session-save-redis-db=2 --session-save-redis-port=6379
```

### How do I set up Elastic Search?

```
bin/magento config:set --lock-config catalog/search/enable_eav_indexer 0
bin/magento config:set --lock-config catalog/search/engine [elasticsearch6 OR  elasticsuite]
bin/magento config:set --lock-env catalog/search/elasticsearch6_server_port 9200
bin/magento config:set --lock-env catalog/search/elasticsearch6_server_hostname localhost
```

### How do I set up mailhog?

```
composer require mageplaza/module-smtp
php bin/magento setup:upgrade
bin/magento config:set --lock-env system/smtp/disable 0
bin/magento config:set --lock-env system/smtp/host localhost
bin/magento config:set --lock-env system/smtp/port 1025
```

### How do I set up RabbitMQ?

```
bin/magento setup:config:set --amqp-host=localhost --amqp-port=5672 --amqp-user=guest --amqp-password=guest
http://localhost:15672
```

### How do I set up Sphinx?

No support yet.
