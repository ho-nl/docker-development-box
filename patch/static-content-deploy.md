# Patch static-content-deploy relative symlinks

Makes the static content deploy use relative symlinks in developer mode. Does not affect production mode.

Note that this patch requires Magento 2.4.2 or above. See
https://github.com/ho-nl/docker-development-box/blob/321b50ab96dcf1a3d63b34b999dc401291e24132/patch/static-content-deploy.diff for older versions of Magento 2.

## Installation

- Ensure `vaimo/composer-patches` is installed in your project.
- Add the following to your projects' `composer.json`:

```
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
