# Changelog

All notable changes to this project will be documented in this file, in reverse
chronological order by release.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [HEAD]

### Added

- Varnish bypass for blackfire.io
- Install: Added zsh support

### Changed

- Revert: Mysql: Disable stats for SHOW TABLE STATUS to improve performance.
- Install: Cleaned output of install script
- Install: Hide launchctl unload warning
- Install: Better success message

## [1.0.0-preview.1] - 2020-02-25

### Changed

- Updated README to make installation more clear.
- Mysql: Disable stats for SHOW TABLE STATUS to improve performance.

## [1.0.0-preview.0] - 2020-02-24

### Added

- Initial Release of the **🐳 Reach Digital Magento 2 Docker+local hybrid
  development environment. 🐳**: Docker for services, php locally. No sync, no
  mental overhead, no performance penalties.
- Supported srevices: `php`, `nginx`, `https`, `http/2`, `varnish`, `mysql`,
  `elasticsearch`, `rabbitmq`, `mailhog`

