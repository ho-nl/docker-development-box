# Reach Digital Magento 2 Docker+local hybrid development environment.

Docker for services, php locally. No sync, no mental overhead, not performance penalties.

## Reasoning

The problem with all the docker devboxes is that they require you to run everything inside a
container/virual machine. The problem with running everything in a vm is that you  need to
have files available in your box. But you also need to have files outside your vm, because
programs like PHPStorm and others do not accept network drives.

This leaved us with solutions like [docker-sync](http://docker-sync.io/),
[nfs](https://docs.docker.com/v17.12/datacenter/dtr/2.1/guides/configure/use-nfs/),
[unison](https://www.cis.upenn.edu/~bcpierce/unison/),
[mutagen](https://mutagen.io/). Although a solution like mutagen is decently fast, it still is a sync.

The reason a sync is bad is because it (1) requires additional HDD space and (2) adds additional 
mental overhead e.g.: are my files synced?, where should I execute bin/magento, where should i run nodejs?

By running PHP locally we don't need to have those files in a docker container, so no sync.

## Goals

- It should be possible for a frontend developer without any backend skills to set up a development environment.
- It should be possible for a backend developer to add or upgrade services.
- It should be possible for a backend developer to propegate the changes to the rest of the team.

## Principles

- No magic: As few CLI tools that will automatically 'fix' things for you. Do not use wrappers around
existing tools: php / docker / etc.
- Declarative: Developer should define the final state instead of running upgrade scripts (hence,
docker, auto php switcher).
- Minimal: Use as few cpu cycles and memory as possible.

## Installation

### Install local PHP:

Since we're running a hybrid docker+local system we need to set up PHP to run locally.

Copy the [`install.sh`](./install.sh) and execute to set up PHP locally:
- It will install multiple php versions.
- Register PHP7.x on php-fpm localhost:907x
- Set defaults for opcache/php-fpm pools
- [ ] Switch php version depending on the composer.json version.

### Install docker

1. Install [docker for mac](https://docs.docker.com/docker-for-mac/).
2. Set docker to 4gb memory
3. `brew install ctop`: `htop` for docker.

### Install this package in your project

`composer require reach-digital/docker-devbox`

## Secure certificate

Add [vendor/reach-digital/docker-devbox/hitch/*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem) to your OSX keychain.

- [ ] Create certificate with [mkcert](https://github.com/FiloSottile/mkcert)
