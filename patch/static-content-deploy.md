# Patch static-content-deploy relative symlinks

Makes the static content deploy use relative symlinks in developer mode. Does not affect production mode.

# Installation

1. Install https://github.com/vaimo/composer-patches

2. Add the following to the patches area of your `composer.json`

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
