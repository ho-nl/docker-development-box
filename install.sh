#!/bin/bash

# If you're adding a new version, you need an additional XDEBUG version, not retrieved dynamically.
PHPS='php@8.2 php@8.1 php@7.4 php@7.3 php@7.2'

remove_php() {
  PHP=$1

  PHPVERSION=${PHP//php/}
  PHPVERSION=${PHPVERSION//@/}

  BREW_PREFIX=`brew --prefix`

  PLIST_PATH="$HOME/Library/LaunchAgents/nl.reachdigital.io.$PHP.plist"
  PLIST_PATH_LEGACY="$HOME/Library/LaunchAgents/homebrew.mxcl.$PHP.plist"
  XPLIST_PATH="$HOME/Library/LaunchAgents/nl.reachdigital.io.$PHP-xdebug.plist"
  XPLIST_PATH_LEGACY="$HOME/Library/LaunchAgents/homebrew.mxcl.$PHP-xdebug.plist"

  echo "[$PHP] 🛑 Stopping fpm"
  launchctl unload $PLIST_PATH &>/dev/null
  launchctl unload $PLIST_PATH_LEGACY &>/dev/null
  launchctl unload $XPLIST_PATH &>/dev/null
  launchctl unload $XPLIST_PATH_LEGACY &>/dev/null

  brew unlink "$PHP" &>/dev/null

  echo "[$PHP] 🗑  Uninstalling"
  brew uninstall "$PHP" &>/dev/null
  rm -rf $BREW_PREFIX/etc/php/"$PHPVERSION"
}

install_php() {
  PHP=$1

  PHPVERSION=${PHP//php/}
  PHPVERSION=${PHPVERSION//@/}
  [ -z $PHPVERSION ] && PHPVERSION='7.4'

  PHPFPM=90${PHPVERSION//./}
  XPHPFPM=91${PHPVERSION//./}

  BREW_PREFIX=`brew --prefix`

  PATH_INI=$BREW_PREFIX/etc/php/$PHPVERSION/php.ini
  PATH_INI_XDEBUG=$BREW_PREFIX/etc/php/$PHPVERSION/php-xdebug.ini

  echo "[$PHP] 👷‍ Installing"
  brew reinstall shivammathur/php/"$PHP" >/dev/null

  PHPDIR=$(brew --cellar "$PHP")/$(brew info --json "$PHP" | jq -r '.[0].installed[0].version')
  echo "[$PHP] 👷 Php path: $PHPDIR"

  echo "[$PHP] ⚡️ Configuring memory_limit, opcache"
  sed -i '' 's/^memory_limit.*/memory_limit = 4096M/g' $PATH_INI
  sed -i '' 's/^max_input_vars.*/max_input_vars = 10000/g' $PATH_INI
  sed -i '' 's/^post_max_size.*/post_max_size = 500M/g' $PATH_INI
  sed -i '' 's/^upload_max_filesize.*/upload_max_filesize = 500M/g' $PATH_INI
  sed -i '' 's/^;opcache.memory_consumption=128/opcache.memory_consumption=512/g' $PATH_INI
  sed -i '' 's/^;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=24/g' $PATH_INI
  sed -i '' 's/^;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g' $PATH_INI
  sed -i '' 's/^;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=130986/g' $PATH_INI
  sed -i '' "s|^;error_log = php_errors.log|;error_log = $BREW_PREFIX/var/log/php@$PHPVERSION-errors.log|g" $PATH_INI

  sed -i '' "s/^listen = 127.0.0.1:9000/listen = 127.0.0.1:$PHPFPM/g" $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm.d/www.conf
  sed -i '' 's/^pm = dynamic/pm = ondemand/g' $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm.d/www.conf
  sed -i '' 's/^pm.max_children = 5/pm.max_children = 20/g' $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm.d/www.conf
  sed -i '' 's/^;pm.process_idle_timeout = 10s;/pm.process_idle_timeout = 10s;/g' $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm.d/www.conf

  echo "[$PHP] 🐞 Installing xdebug"

  # Set correct xdebug version depending on PHP version. For PHP 8.2 and up, xdebug 3.2 is needed
  XDEBUG_VERSION='3.1.6'
  [ $PHPVERSION == '8.2' ] && XDEBUG_VERSION='3.2.1'

  brew unlink $PHP && brew link --force --overwrite $PHP > /dev/null

  # Use pecl upgrade, so it fails gracefully if already installed.
  $PHPDIR/bin/pecl upgrade xdebug-$XDEBUG_VERSION

  [ $PHPVERSION = '7.2' ] && PHP_EXTENSION_API='20170718'
  [ $PHPVERSION = '7.3' ] && PHP_EXTENSION_API='20180731'
  [ $PHPVERSION = '7.4' ] && PHP_EXTENSION_API='20190902'
  [ $PHPVERSION = '8.1' ] && PHP_EXTENSION_API='20210902'
  [ $PHPVERSION = '8.2' ] && PHP_EXTENSION_API='20220829'
  echo "[$PHP] 🐞 Xdebug path: $PHPDIR/pecl/$PHP_EXTENSION_API/xdebug.so"

  # Set up separate ini, so we only load xdebug through the xdebug fpm-php instance
  # On initial installs, the extension line is added to the base php.ini, so remove it
  sed -i '' "s/^zend_extension=\"xdebug.so\"//" $PATH_INI
  cp $PATH_INI $PATH_INI_XDEBUG
  gsed -i "1 i\zend_extension=\"$PHPDIR/pecl/$PHP_EXTENSION_API/xdebug.so\"" $PATH_INI_XDEBUG
  gsed -i "1 i\xdebug.mode=debug" $PATH_INI_XDEBUG
  gsed -i "1 i\xdebug.max_nesting_level=2000" $PATH_INI_XDEBUG

  # Set up separate php-fpm ini
  cp $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm.conf $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm-xdebug.conf
  sed -i '' "s~^include=$BREW_PREFIX/etc/.*~include=$BREW_PREFIX/etc/php/$PHPVERSION/php-fpm-xdebug.d/*.conf~g" $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm-xdebug.conf
  cp -rp $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm.d $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm-xdebug.d
  sed -i '' "s/^listen = 127.0.0.1:$PHPFPM/listen = 127.0.0.1:$XPHPFPM/g" $BREW_PREFIX/etc/php/"$PHPVERSION"/php-fpm-xdebug.d/www.conf

  echo "Installing Imagick for PHP"
  # We pipe `yes ''` into pecl, as imagick asks for input during compilation and would otherwise get stuck.
  yes '' | $PHPDIR/bin/pecl upgrade imagick

  echo "[$PHP] ✅ Installed"
  echo ""
}

start_php() {
  PHP=$1

  PHPVERSION=${PHP//php/}
  PHPVERSION=${PHPVERSION//@/}
  [ -z $PHPVERSION ] && PHPVERSION='7.4'

  PHPFPM=90${PHPVERSION//./}
  XPHPFPM=91${PHPVERSION//./}

  BREW_PREFIX=`brew --prefix`

  PHPDIR=$(brew --cellar "$PHP")/$(brew info --json "$PHP" | jq -r '.[0].installed[0].version')

  PLIST_PATH="$HOME/Library/LaunchAgents/nl.reachdigital.io.$PHP.plist"
  XPLIST_PATH="$HOME/Library/LaunchAgents/nl.reachdigital.io.$PHP-xdebug.plist"

  rm -f $PLIST_PATH
  rm -f $XPLIST_PATH

  PLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
    <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>nl.reachdigital.io.$PHP.plist</string>
        <key>ProgramArguments</key>
        <array>
            <string>$PHPDIR/sbin/php-fpm</string>
            <string>--nodaemonize</string>
            <string>--fpm-config</string>
            <string>$BREW_PREFIX/etc/php/$PHPVERSION/php-fpm.conf</string>
            <string>--php-ini</string>
            <string>$BREW_PREFIX/etc/php/$PHPVERSION/php.ini</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>$BREW_PREFIX/var</string>
        <key>StandardErrorPath</key>
        <string>$BREW_PREFIX/var/log/php@$PHPVERSION-fpm-stderr.log</string>
        <key>StandardOutPath</key>
        <string>$BREW_PREFIX/var/log/php@$PHPVERSION-fpm-stdout.log</string>
    </dict>
</plist>
"
  echo $PLIST >$PLIST_PATH

  XPLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
    <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>nl.reachdigital.io.$PHP-xdebug.plist</string>
        <key>ProgramArguments</key>
        <array>
            <string>$PHPDIR/sbin/php-fpm</string>
            <string>--nodaemonize</string>
            <string>--fpm-config</string>
            <string>$BREW_PREFIX/etc/php/$PHPVERSION/php-fpm-xdebug.conf</string>
            <string>--php-ini</string>
            <string>$BREW_PREFIX/etc/php/$PHPVERSION/php-xdebug.ini</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>$BREW_PREFIX/var</string>
        <key>StandardErrorPath</key>
        <string>$BREW_PREFIX/var/log/php@$PHPVERSION-xdebug-fpm-stderr.log</string>
        <key>StandardOutPath</key>
        <string>$BREW_PREFIX/var/log/php@$PHPVERSION-xdebug-fpm-stdout.log</string>
    </dict>
</plist>
"
  echo $XPLIST >$XPLIST_PATH

  #echo "[$PHP]  🚀 Starting + registering on localhost:$PHPFPM"
  launchctl unload -w $PLIST_PATH &>/dev/null
  launchctl load -w $PLIST_PATH

  #echo "[$PHP]  🚀 Starting + registering on localhost:$XPHPFPM with xdebug"
  launchctl unload -w $XPLIST_PATH &>/dev/null
  launchctl load -w $XPLIST_PATH
}

echo "
🧼 Cleaning MacOS
"

for PHP in $PHPS; do
  remove_php "$PHP"
done

echo "
Installing mysql-client, gnu-sed, pv, jq, imagemagick, pkg-config"
brew install gnu-sed mysql-client@8.4 pv jq imagemagick pkg-config &>/dev/null

brew link mysql-client --force &>/dev/null

echo "
🚰 Adding shivammathur/php tap for legacy PHP support
"
brew tap shivammathur/php

echo "
🐘 Installing php services
"

for PHP in $PHPS; do
  install_php "$PHP"
done

echo "
💅 Starting services
"

for PHP in $PHPS; do
  start_php "$PHP"
done

echo "
If everything went well the 'err' column should be 0. You can now see these processes in activity monitor. 🎉

In case the PHP 7.2 services failed to start, this may be due to a known issue, refer to the README for a possible
workaround.

pid     err     name
"
launchctl list | grep reachdigital

echo "
🎉 Done"
