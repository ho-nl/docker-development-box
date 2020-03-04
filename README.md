# 🐳 Reach Digital Magento 2 Docker+local hybrid development environment. 🐳

Docker for services, php locally. No sync, no mental overhead, no performance
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

## Requirements

- Recent OSX

## Global installation (only once)

### Cleanup your system

Since we're running some things locally it probably is a good time to clean some
stuff up.

- Run `brew doctor` and make sure you don't have errors.
- Run `brew update` to update to the latest version.

You should not have any services running like.

- `php`: find them with `brew list | grep php`, uninstall them.
- `httpd`:
  [Disable apache](https://apple.stackexchange.com/questions/119674/disable-apache-autostart/119678)
  that is OSX native. http://localhost/ should not return anything.
- `mysql`: uninstall or disable mysql, or at least make sure it doesnt run on
  the default MySQL port.
- `nginx`: uninstall

Take a look at `~/.bash_profile` or `~/.zshrc` and make sure it doesn't contain
any references to `/usr/local/Cellar/php*`.

### Installing services

Since we're running a hybrid docker+local system we need to set up PHP to run
locally.

```bash
# Cleans existing brew php (will not remove Valet stuff) + installs php on OSX!
curl -s https://raw.githubusercontent.com/ho-nl/docker-development-box/master/install.sh?token=AAJP2AECWY7UWCOGGX7EDS26LEH4G | bash -s -- -i
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

### Install docker

1. Install [docker for mac](https://docs.docker.com/docker-for-mac/).
2. Exclude `~/Library/Containers` from your backups
3. `brew install ctop`: `htop` for docker.
4. Set CPU's to 6 and memory to 8GB (should me _more_ than enough)

### Install local certificate

- Download the raw .pem file (Open Raw, then CMD + S):
- [./hitch/\*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem)
- Open keychain.app, add this file.
- Open certificate and trust the certificate.

You are now done with the global installation 🎉

## Project installation

- Install this in the project
  `composer require --dev reach-digital/docker-devbox`
- Install `static-content-deploy`
  [patch](patch/static-content-deploy.md) and remove
  `pub/static/frontend/*`.
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

You now have all services set up 🎉. See individual services below to set urls,
caches, etc.

## Settings for `mysql` `elasticsearch`, `rabbitmq`, `mailhog`, etc.

### How do I use xdebug?

- Web: Xdebug should work by default when you have the
  [Xdebug helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)
  installed + PHPStorm is listening to connections.
- Cli: Use
  `XDEBUG_CONFIG="" php -c /usr/local/etc/php/7.2/php-xdebug.ini bin/magento`
- Tests: Create a local interpreter, the PHP version you're looking for should
  be suggested and add the `🐞 Xdebug path:` to enable xdebug (you should have
  seen that with the installation). The path is something like
  `/usr/local/Cellar/php/7.4.3/pecl/20190902/xdebug.so` (lookup your exact path)

### How do I set up my cron?

[default setup](https://devdocs.magento.com/guides/v2.3/config-guide/cli/config-cli-subcommands-cron.html#create-the-magento-crontab)

### Where can I find logs?

- For all other services, start `ctop` and press `<-` on your keyboard.
- phplogs: tail -f /usr/local/var/log/php\* (will probably be empty as it will
  only output true errors)

### How do I set up urls/https?

https _only_ with [hitch](https://github.com/varnish/hitch). The docker
container does _not_ support http, _only_ https.

```
bin/magento config:set --lock-env web/unsecure/base_url https://blabla.localhost.reachdigital.io/
bin/magento config:set --lock-env web/secure/base_url https://blabla.localhost.reachdigital.io/
# You can use any domain that points to 127.0.0.1, you can't use https://localhost because Magento can't handle that.
# *.localhost.reachdigital.io always resolves to 127.0.0.1
```

### How do I use and set up Varnish?

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

How do I flush Redis directly when `bin/magento` is broken?
`composer down && composer up -d`

### How do I set up Elastic Search?

```
bin/magento config:set --lock-config catalog/search/enable_eav_indexer 0
bin/magento config:set --lock-config catalog/search/engine [elasticsearch6 OR  elasticsuite]
bin/magento config:set --lock-env catalog/search/elasticsearch6_server_port 9200
bin/magento config:set --lock-env catalog/search/elasticsearch6_server_hostname localhost
```

### How do I set up MailHog?

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

## How do I connect to my container over SSH directly?

1. Open up `ctop`
2. <key>⮐</key> on your service
3. `exec shell`

Please note that the containers are as minimal as possible, so not all common
tools are available, but you should be able to get around.

## I want to create a custom configuration for a service.

Everything is set up via the docker-compose.yml file. You see paths to the
configuration file there.

1. Change the path to your custom configuration file.
2. Run `docker-compose down && docker-compose up -d`
3. Changes should be applied, check `ctop` if your container is able to start.
