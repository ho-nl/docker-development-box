# Patch static-content-deploy relative symlinks

Makes the static content deploy use relative symlinks in developer mode. Does not affect production mode.

Without this patch, nginx will not be able to directly read static content files, which causes them to be resolved through Magento/PHP, greatly reducing performance.

# Installation

1. Install https://github.com/vaimo/composer-patches

2. Add the following to the patches area of your `composer.json`

  ⚠  For Magento >=2.4.2, use `./vendor/reach-digital/docker-devbox/patch/2.4.2-static-content-deploy.diff`

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



