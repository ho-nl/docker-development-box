# Reach Digital Docker+local hybrid development environment.

Mimics other moder

No sync, no mental overhead, not performance penalties.

Goals: Be absolutely minimal and as transparent as possible.

## History

Originally started working with a MAMP setup, migrated to a brew-only setup, migrated to vagrant virtual boxes to a hybrid.

## Installation

Since we're running a hybrid docker+local system we need to set up PHP to run locally.

`/usr/local/etc/php/7.2/php-fpm.d/www.conf`

`vi /usr/local/etc/php/7.2/php.ini`
- `memory_limit = 4096M`

Set docker to 4gb memory.

## Secure certificate

Add [*.localhost.reachdigital.io.pem](./hitch/*.localhost.reachdigital.io.pem) to your keychain.

## Tools

`brew install ctop`
