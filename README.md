# Reach Digital Magento 2 Docker+local hybrid development environment.

Docker for services, php locally. No sync, no mental overhead, not performance penalties.

## Reasoning

The problem with all the docker devboxes is that they require running everything inside a
container/virual machine. The problem with running everything in a vm is that files need to
have files available in the vm. BUT it also also need to have files outside the vm, because
programs like PHPStorm and others do not accept network drives.

There are solutions to solve this, like [docker-sync](http://docker-sync.io/),
[nfs](https://docs.docker.com/v17.12/datacenter/dtr/2.1/guides/configure/use-nfs/),
[unison](https://www.cis.upenn.edu/~bcpierce/unison/),
[mutagen](https://mutagen.io/). Although a solution like mutagen is decently fast, it still
is a sync and a sync can never be as fast as no-sync.

The reason a sync is bad is because it (1) requires additional HDD space and (2) adds additional 
mental overhead e.g.: are my files synced?, where should I execute bin/magento, where
should i run nodejs?

By running PHP locally we don't need to have those files in a docker container, so no sync.

## Goals

- It should be possible for a frontend developer without any backend skillsto set up a
development environment.
- It should be possible for a backend developer to add or upgrade services.
- It should be possible for a backend developer to propegate the changes to the rest
of the team.

## Principles

- No magic: As few CLI tools that will automatically 'fix' things. Do not use wrappers around
existing tools: php / docker / etc.
- Declarative: Developer should define the final state instead of running upgrade scripts (hence,
docker, auto php switcher).
- Minimal: Use as few cpu cycles and memory as possible.

## Installation

Since we're running a hybrid docker+local system we need to set up PHP to run locally.

```bash
# Destructively installs php on OSX!
curl -s https://raw.githubusercontent.com/ho-nl/docker-development-box/master/install.sh?token=AAJP2AGUXJ5PPIULPDG76CK6GH7YS | bash -s -- -i
# Save the `🏗  Xdebug path: ...` somewhere to setup xdebug in PHPStorm.
```

- It will (re)install multiple php-fpm services, one for each version (port: 9072, 9073, 9074) and
one for each version with xdebug (port: 9172, 9173, 9174).
- It doesn't clean `valet-php@xx/nginx/apache/mysql` etc, but those should probably be uninstalled.
- It doesn't clean `./bash_profile`, which can cause issues. `./bash_profile` must contain
`export PATH="/usr/local/bin/php:$PATH"`, but must not contain any references to `/usr/local/Cellar/php*`.

### Install docker

1. Install [docker for mac](https://docs.docker.com/docker-for-mac/).
2. `brew install ctop`: `htop` for docker.
3. Install this in the project `composer require reach-digital/docker-devbox`
4. Commit the `docker-compose.yml` file to prevent future accidental changes.

### Install local certificate

Add [vendor/reach-digital/docker-devbox/hitch/*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem)
to your OSX keychain.

- [ ] Create certificate with [mkcert](https://github.com/FiloSottile/mkcert)

## Usage

To find passwords, startup different things 

### Start with logging:
- Start: `docker-compose up`
- Stop: `Ctrl+C`

### Start in background:
- Start: `docker-compose up -d`
- Loggin: `ctop`
- Stop: `docker-compose stop`

### Delete images:
- `docker-compose down`

### Delete mysql/elasticsearch database:
- `rm -rf var/.esdata`
- `rm -rf var/.mysqldata`

1. Go to the root of your project: `docker-compose up` to download and start all containers. Press `Ctrl+C` to stop.
2. Read the docker-compose.yml for db passwords, etc.

### Switch PHP versions

Since automatic php switching isn't implemented yet, you can switch to a different php version by running:

```bash
brew unlink php@7.3
brew link php@7.2 --force
php -v
```

Should now show the right version. If it doesn't there might be still be a version linked or
your ~/.bash_profile should be cleaned up.

### Setup debugging with PHP

