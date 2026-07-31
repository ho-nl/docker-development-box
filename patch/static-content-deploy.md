# Patch static-content-deploy relative symlinks

Makes the static content deploy use relative symlinks in developer mode. Does not affect production mode.

The patch comes in two variants, which are identical apart from the framework package they target.
Pick the one matching your project:

| Project | Patch |
| --- | --- |
| Magento 2.4.2 or above (`magento/framework`) | `patch/static-content-deploy.diff` |
| Mage-OS (`mage-os/framework`) | `patch/mageos-static-content-deploy.diff` |

For Magento versions below 2.4.2, see
https://github.com/ho-nl/docker-development-box/blob/321b50ab96dcf1a3d63b34b999dc401291e24132/patch/static-content-deploy.diff.

## Installation

- Ensure `vaimo/composer-patches` is installed in your project.
- Add the snippet for your project below to your projects' `composer.json`.

### Magento

```json
{
  "extra": {
    "patches": {
      "*": {
        "Patch static-content-deploy relative symlinks": {
          "source": "./vendor/reach-digital/docker-devbox/patch/static-content-deploy.diff"
        }
      }
    }
  }
}
```

### Mage-OS

```json
{
  "extra": {
    "patches": {
      "*": {
        "Patch static-content-deploy relative symlinks": {
          "source": "./vendor/reach-digital/docker-devbox/patch/mageos-static-content-deploy.diff"
        }
      }
    }
  }
}
```
