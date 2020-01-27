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

Since we're running a hybrid docker+local system we need to set up PHP to run
locally.

```bash
# Cleans (destructively) + installs php on OSX!
curl -s https://raw.githubusercontent.com/ho-nl/docker-development-box/master/install.sh?token=AAJP2AGUXJ5PPIULPDG76CK6GH7YS | bash -s -- -i
# Save the `🏗  Xdebug path: ...` somewhere to setup xdebug in PHPStorm.
```

- It will (re)install multiple php-fpm services, one for each version (port:
  9072, 9073, 9074) and one for each version with xdebug (port: 9172, 9173,
  9174).
- It doesn't clean `valet-php@xx/nginx/apache/mysql` etc, but those should
  probably be uninstalled.
- It doesn't clean `./bash_profile`, which can cause issues. `./bash_profile`
  must contain `export PATH="/usr/local/bin/php:$PATH"`, but must not contain
  any references to `/usr/local/Cellar/php*`.

### Install docker

1. Install [docker for mac](https://docs.docker.com/docker-for-mac/).
2. Exclude `~/Library/Containers` from your backups
3. `brew install ctop`: `htop` for docker.

### Install local certificate

Add
[vendor/reach-digital/docker-devbox/hitch/\*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem)
to your OSX keychain.

- [ ] Create certificate with [mkcert](https://github.com/FiloSottile/mkcert)

## Project installation

- Install this in the project `composer require reach-digital/docker-devbox`
- Install `varnish` and `static-content-deploy`
  [patches](https://github.com/ho-nl/magento2-ReachDigital_Patches).
- Commit the `docker-compose.yml` file to prevent future accidental changes.

## Usage

**Start with logging:**

- Start: `docker-compose up`
- Stop: `Ctrl+C`

**Start in background:**

- Start: `docker-compose up -d`
- Loggin: `ctop`
- Stop: `docker-compose stop`

**Delete images:**

- `docker-compose down`

**Delete mysql/elasticsearch database:**

- `rm -rf var/.esdata`
- `rm -rf var/.mysqldata`

### Settings for `mysql` `elasticsearch`, `rabbitmq`, `mailhog`

Everything can be found in [docker-compose.yml](./docker-compose.yml).

### Switch PHP versions

Since automatic php switching isn't implemented yet, you can switch to a
different php version by running:

```bash
brew unlink php@7.3
brew link php@7.2 --force
php -v
```

Should now show the right version. If it doesn't there might be still be a
version linked or your ~/.bash_profile should be cleaned up.

### Setup xdebug

1. Create a local interpreter, the PHP version you're looking for should be
   suggested.
2. Add the `🏗 Xdebug path:` to enable xdebug.

### [Cron](https://devdocs.magento.com/guides/v2.3/config-guide/cli/config-cli-subcommands-cron.html#create-the-magento-crontab)
