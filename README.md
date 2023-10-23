# 🐳 Reach Digital Magento 2.4 Docker+local hybrid development environment. 🐳

⚠  _For Magento 2.3, see the
[2.x branch](https://github.com/ho-nl/docker-development-box/tree/2.x)._

Docker for services, php locally. No sync, no mental overhead, no performance
penalties.  
`php`, `nginx`, `https`, `http/2`, `varnish`, `mysql` `elasticsearch`,
`rabbitmq`, `mailhog`

## Reasoning

Docker is easy, docker scales, we love Docker, but docker's volume mounting is
slow, we can't have slow.

The problem with all the docker devboxes is that they require running php inside
a vm. The problem with php in a VM is that files need to be available in the VM,
but it also needs to have files outside the VM, because programs like PHPStorm
and others do not accept network drives.

Sync is slower than no sync. [docker-sync](http://docker-sync.io/),
[unison](https://www.cis.upenn.edu/~bcpierce/unison/),
[mutagen](https://mutagen.io/) offer good sync solutions, but always slower than
no sync.

Hovever, syncs require additional HDD space and additional mental overhead: Are
my files synced?, Is my sync broken? Are there sync conflicts? Why did that file
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

- `php`: find them with `brew list | grep php`, uninstall them using
  `brew uninstall —f <packages>`. With the force flag you'll delete all
  installed versions of formula.
- `httpd`:
  [Disable apache](https://apple.stackexchange.com/questions/119674/disable-apache-autostart/119678)
  that is OSX native. http://localhost/ should not return anything.
- `mysql`: uninstall or disable mysql, or at least make sure it doesnt run on
  the default MySQL port.
- `nginx`: uninstall

Take a look at `~/.bash_profile` or `~/.zshrc` and make sure it doesn't contain
any references to `$BREW_PREFIX/Cellar/php*`.

### Installing services for Magento 2.4

Since we're running a hybrid docker+local system we need to set up PHP to run
locally.

```bash
# Magento 2.4 (for 2.3, see the 2.x branch)
# Cleans existing brew php (will not remove Valet stuff) + installs php on OSX!
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ho-nl/docker-development-box/master/install.sh)"
```

It will (re)install multiple php-fpm services, one for each version (port: 9072,
9073, 9074) and one for each version with xdebug (port: 9172, 9173, 9174).

#### Switch PHP versions

```bash
brew unlink php@7.3
brew link php@7.4 --force
php -v
```

Should now show the right version. If it doesn't there might be still be a
version linked, or your ~/.bash_profile should be cleaned up, or you need to
reopen your CLI.

### Install docker

1. Install latest version of 
   [docker for mac]([https://docs.docker.com/desktop/release-notes/]).
2. Start Docker
3. Exclude `~/Library/Containers` from your backups
4. `brew install ctop`: can be used to show container metrics.
5. Open Docker -> Preferences
6. Set memory to 6-8 GB

### Install nfs

Note that the `-mapall=501:20` part below refers to your user ID (`501`) and
the `staff` (`20`) user group ID. You may need to adjust your user ID if isn't
`501`. You can check this by running `id`.

1. `sudo nano /etc/exports` add:
   `/System/Volumes/Data -alldirs -mapall=501:20 localhost`
2. `sudo nano /etc/nfs.conf` add: `nfs.server.mount.require_resv_port = 0`
3. `sudo nfsd restart`

[Based on this article](https://www.jeffgeerling.com/blog/2020/revisiting-docker-macs-performance-nfs-volumes)

### Install local certificate

- Download the raw .pem file (Open Raw, then CMD + S):
- [./hitch/\*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem)
- Open keychain.app, add this file (you can drag and drop this file in the keychain
  app, under the `Login` tab).
- Open certificate and trust the certificate (do this by right clicking on the entry, choosing 'Get Info', and choose 'Always trust' under the 'Trust' section)

You are now done with the global installation 🎉

## Project installation

This covers initially adding docker-devbox support to a Magento project; if your project
already has docker-devbox support added, please refer to the projects' own README.md.

- Install this in the project:
  - Magento 2.3: [2.x branch](https://github.com/ho-nl/docker-development-box/tree/2.x)
  - Magento 2.4: `composer require reach-digital/docker-devbox ^3.0.0`  
- Install `static-content-deploy` [patch](patch/static-content-deploy.md) and
  remove existing static symlinked content: `rm -rf pub/static/*/*`.
- Disable services you don't need in `docker-compose.yml` (required: `hitch`,
  `varnish`, `nginx`, `db` and `elasticsearch`).
- Commit the `docker-compose.yml` file to prevent future accidental changes.
- Update or create an env.php file and with the following info
  ```
    'host' => '127.0.0.1',
    'dbname' => 'magento',
    'username' => 'root',
    'password' => 'magento',
  ```
- Create a setup script for the base-urls and run it.

## Usage

- Start: `docker-compose up -d`
- Logging: `ctop`
- Stop: `docker-compose down`

You now have all services set up 🎉. See individual services below to set urls,
caches, etc.

**Deleting data (mysql/elasticsearch):**

- `docker-compose down`
- `rm -rf var/.esdata/*`
- `rm -rf var/.mysqldata/*`
- `docker-compose up -d`

Be sure to give MySQL a minute or two to re-initialize the data directory - during
this time it will not accept connections.

## Settings for `mysql` `elasticsearch`, `rabbitmq`, `mailhog`, etc.

### How do I use xdebug?

- Web: Xdebug should work by default when you have the
  [Xdebug helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)
  installed + PHPStorm is listening to connections.
- Command line: you can add the following alias to your `~/.bash_profile` or `~/.zshrc`, this will auto-detect
  your active PHP version, and let you debug using something like `phpd bin/magento ...`:
  ```
  alias phpd="XDEBUG_SESSION=1 php -c \$(brew --prefix)/etc/php/\$(php -v | head -n1 | cut -c 5-7)/php-xdebug.ini"
  ```
- Tests: Create a local interpreter in PhpStorm, the PHP version you're looking for should
  be suggested. Configure the `🐞 Xdebug path:` to enable xdebug (from the output of the installation script). The path
  is something like `/usr/local/Cellar/php/7.4.3/pecl/20190902/xdebug.so`. You can look up your exact path in your `php-xdebug.ini`.

### How do I set up my cron?

[default setup](https://devdocs.magento.com/guides/v2.3/config-guide/cli/config-cli-subcommands-cron.html#create-the-magento-crontab)

### Where can I find logs?

- For all other services, start `ctop` and press `<-` on your keyboard.
- phplogs: ``tail -f `brew --prefix`/var/log/php*`` (will probably be empty as it will
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
### How do I set up multiple websites?

To allow our nginx setup to work with multiple websites we need to make some changes to our docker-compose.yml
We've already defined the needed nginx params as environment parameters for nginx.
These should be uncommented. 

Nginx won't start without a mapping for the `mage_run_code` param.
We have to add a new conf file, for example `nginx-map.conf`
`$MAGE_RUN_CODE` is the relevant `website_code` or `storeview_code`

```
map $http_host $MAGE_RUN_CODE {
    default '';
    blabla-dutch.localhost.reachdigital.io 'blabla_dutch';
    blabla-german.localhost.reachdigital.io 'blabla_german';
}
```
Add the file path to the nginx volumes, for exmaple:
```dockerfile
    volumes:
      - ./nginx-map.conf:/etc/nginx/conf.d/map.conf:ro
```
Your website or storeview should now be available.

For more information check the magento docs: https://experienceleague.adobe.com/docs/commerce-operations/configuration-guide/multi-sites/ms-nginx.html

### How do I use and set up Varnish?

Cache by default with https://www.varnish-software.com/

```
bin/magento setup:config:set --http-cache-hosts=127.0.0.1:6081
bin/magento config:set --lock-config system/full_page_cache/caching_application 2
```

- You can use `bin/magento cache:clean` or `cache:flush` to flush Varnish.
- You can use `CMD+SHIFT+R` to bypass Varnish for any page.
- You can use port 6082 and `docker-devbox-varnish-secret` as shared secret to connect with the Varnish management interface.

### How do I set up Redis?

```
php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-db=0 --cache-backend-redis-port=6379
php bin/magento setup:config:set --session-save=redis --session-save-redis-db=2 --session-save-redis-port=6379
```

How do I flush Redis directly when `bin/magento` is broken?
`docker-compose exec redis redis-cli flushall`

### How do I set up Elastic Search?

```
bin/magento config:set --lock-config catalog/search/enable_eav_indexer 0
bin/magento config:set --lock-config catalog/search/engine [elasticsearch7 OR  elasticsuite]
bin/magento config:set --lock-env catalog/search/elasticsearch6_server_port 9200
bin/magento config:set --lock-env catalog/search/elasticsearch6_server_hostname localhost
```

### How do I set up MailHog?

```
composer require magepal/magento2-gmailsmtpapp
php bin/magento setup:upgrade
bin/magento config:set --lock-env system/smtp/disable 0
bin/magento config:set --lock-env system/gmailsmtpapp/active 1
bin/magento config:set --lock-env system/gmailsmtpapp/auth NONE
bin/magento config:set --lock-env system/gmailsmtpapp/ssl none
bin/magento config:set --lock-env system/gmailsmtpapp/smtphost localhost
bin/magento config:set --lock-env system/gmailsmtpapp/smtpport 1025
```

Note that when trying to visit MailHog via your browser, use `http` instead of `https`.

### How do I set up RabbitMQ?

```
bin/magento setup:config:set --amqp-host=localhost --amqp-port=5672 --amqp-user=guest --amqp-password=guest
http://localhost:15672
```

### How do I set up Ngrok?
Ngrok exposes local servers to the public internet over secure tunnels.

```
http://localhost:4551
Update base urls with tunnel url shown on webpage.
```

By default an unregistered session is started, this will limit the connections per minute. Adding your authtoken using environment parameters will grant you access to more features and longer session times.
```
  - PARAMS=http -region=eu --authtoken=<token> nginx:80
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

## How do I restart php-fpm?

`pkill php-fpm`

## Commits

Commits are validated with https://github.com/conventional-changelog/commitlint

Gittower: Gittower doesn't properly read your PATH variable and thus commit
validation doesn't work. Use `gittower .` to open this repo.

## Troubleshooting

### The Compose file './docker-compose.yml' is invalid

`ERROR: The Compose file './docker-compose.yml' is invalid because: Unsupported config option for services.mailhog: 'platform'`

Please update Docker to fix this error. This error happens because your Docker version
is too low and does not support the `platform` option. This option is used in recent
versions of docker-development-devbox to enable support for both Intel and Apple
Silicon macbooks.

### docker-composer and/or ctop are not able to connect to the Docker daemon

`ERROR: Couldn't connect to Docker daemon. You might need to start Docker for Mac.`

This may happen if you've upgraded from an old version of Docker. In more recent
versions of docker, the socket file through which one can connect with the deamon
was moved to `~/.docker/run/docker.sock`. Programs like `ctop` and
`docker-composer` use the symlink at `/var/run/docker.sock` which may still point
to the old path.

To correct this, run the following:

```sh
sudo ln -sf ~/.docker/run/docker.sock /var/run/docker.sock
```


