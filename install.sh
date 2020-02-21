#!/bin/bash

# If you're adding a new version, you need an additional XDEBUG version, not retrieved dynamically.
PHPS='php@7.2 php@7.3 php'

spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf "%c   " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

remove_php() {
  PHP=$1

  PHPVERSION=${PHP//php/}
  PHPVERSION=${PHPVERSION//@/}
  [ -z $PHPVERSION ] && PHPVERSION='7.4'

  PHPFPM=90${PHPVERSION//./}
  XPHPFPM=91${PHPVERSION//./}

  echo "[$PHP] 🛑 Stopping fpm"
  launchctl unload "$HOME/Library/LaunchAgents/homebrew.mxcl.$PHP.plist" &>/dev/null &
  spinner
  launchctl unload "$HOME/Library/LaunchAgents/homebrew.mxcl.$PHP-xdebug.plist" &>/dev/null &
  spinner

  brew unlink "$PHP" &>/dev/null &
  spinner

  echo "[$PHP] 🗑  Uninstalling"
  brew uninstall "$PHP" &>/dev/null &
  spinner
  rm -rf /usr/local/etc/php/"$PHPVERSION"
}

install_php() {
  PHP=$1

  PHPVERSION=${PHP//php/}
  PHPVERSION=${PHPVERSION//@/}
  [ -z $PHPVERSION ] && PHPVERSION='7.4'

  PHPFPM=90${PHPVERSION//./}
  XPHPFPM=91${PHPVERSION//./}

  echo "[$PHP] 👷‍ Installing"
  brew install "$PHP" >/dev/null &
  spinner

  PHPDIR=$(brew --cellar "$PHP")/$(brew info --json "$PHP" | jq -r '.[0].installed[0].version')
  echo "[$PHP] 👷 Php path: $PHPDIR"

  echo "[$PHP] ⚡️ Configuring memory_limit, opcache"
  sed -i '' 's/^memory_limit.*/memory_limit = 4096M/g' /usr/local/etc/php/"$PHPVERSION"/php.ini
  sed -i '' 's/^;opcache.memory_consumption=128/opcache.memory_consumption=512/g' /usr/local/etc/php/"$PHPVERSION"/php.ini
  sed -i '' 's/^;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=24/g' /usr/local/etc/php/"$PHPVERSION"/php.ini
  sed -i '' 's/^;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g' /usr/local/etc/php/"$PHPVERSION"/php.ini
  sed -i '' 's/^;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=130986/g' /usr/local/etc/php/"$PHPVERSION"/php.ini

  sed -i '' "s/^listen = 127.0.0.1:9000/listen = 127.0.0.1:$PHPFPM/g" /usr/local/etc/php/"$PHPVERSION"/php-fpm.d/www.conf
  sed -i '' 's/^pm = dynamic/pm = ondemand/g' /usr/local/etc/php/"$PHPVERSION"/php-fpm.d/www.conf
  sed -i '' 's/^pm.max_children = 5/pm.max_children = 20/g' /usr/local/etc/php/"$PHPVERSION"/php-fpm.d/www.conf
  sed -i '' 's/^;pm.process_idle_timeout = 10s;/pm.process_idle_timeout = 10s;/g' /usr/local/etc/php/"$PHPVERSION"/php-fpm.d/www.conf


  echo "[$PHP] 🐞  Installing xdebug"
  brew link "$PHP" --force >/dev/null
  source ~/.bash_profile


  # todo(paales) We can probably migrate to a simple pecl install xdebug
  CURRENT_DIR=$PWD
  XDEBUG_DIR="$HOME/.xdebug$PHP"
  rm -rf $XDEBUG_DIR
  git clone git://github.com/xdebug/xdebug.git $XDEBUG_DIR 2>/dev/null &
  spinner

  cd $XDEBUG_DIR
  echo "[$PHP] 🐞  Building xdebug"

  "$PHPDIR"/bin/phpize >/dev/null &
  spinner

  ./configure --enable-xdebug --enable-shared --with-php-config="$PHPDIR"/bin/php-config >/dev/null &
  spinner

  make clean >/dev/null &
  spinner

  make &>/dev/null &
  spinner

  make install &>/dev/null &
  spinner

  cd $CURRENT_DIR

  brew unlink "$PHP" >/dev/null &
  spinner
  source ~/.bash_profile

  [ $PHPVERSION = '7.2' ] && XDEBUG='20170718'
  [ $PHPVERSION = '7.3' ] && XDEBUG='20180731'
  [ $PHPVERSION = '7.4' ] && XDEBUG='20190902'

  echo "[$PHP] 🐞  Xdebug path: $PHPDIR/pecl/$XDEBUG/xdebug.so"

  cp /usr/local/etc/php/"$PHPVERSION"/php.ini /usr/local/etc/php/"$PHPVERSION"/php-xdebug.ini
  gsed -i "1 i\zend_extension=\"$PHPDIR/pecl/$XDEBUG/xdebug.so\"" /usr/local/etc/php/"$PHPVERSION"/php-xdebug.ini
  gsed -i "1 i\xdebug.remote_enable=1" /usr/local/etc/php/"$PHPVERSION"/php-xdebug.ini
  gsed -i "1 i\xdebug.max_nesting_level=2000" /usr/local/etc/php/"$PHPVERSION"/php-xdebug.ini

  cp /usr/local/etc/php/"$PHPVERSION"/php-fpm.conf /usr/local/etc/php/"$PHPVERSION"/php-fpm-xdebug.conf
  sed -i '' "s~^include=/usr/local/etc/.*~include=/usr/local/etc/php/$PHPVERSION/php-fpm-xdebug.d/*.conf~g" /usr/local/etc/php/"$PHPVERSION"/php-fpm-xdebug.conf
  cp -rp /usr/local/etc/php/"$PHPVERSION"/php-fpm.d /usr/local/etc/php/"$PHPVERSION"/php-fpm-xdebug.d
  sed -i '' "s/^listen = 127.0.0.1:$PHPFPM/listen = 127.0.0.1:$XPHPFPM/g" /usr/local/etc/php/"$PHPVERSION"/php-fpm-xdebug.d/www.conf

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
            <string>/usr/local/etc/php/$PHPVERSION/php-fpm.conf</string>
            <string>--php-ini</string>
            <string>/usr/local/etc/php/$PHPVERSION/php.ini</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>/usr/local/var</string>
        <key>StandardErrorPath</key>
        <string>/usr/local/var/log/php@$PHPVERSION-fpm.log</string>
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
            <string>/usr/local/etc/php/$PHPVERSION/php-fpm-xdebug.conf</string>
            <string>--php-ini</string>
            <string>/usr/local/etc/php/$PHPVERSION/php-xdebug.ini</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>/usr/local/var</string>
        <key>StandardErrorPath</key>
        <string>/usr/local/var/log/php@$PHPVERSION-xdebug-fpm.log</string>
    </dict>
</plist>
"
  echo $XPLIST >$XPLIST_PATH

  #echo "[$PHP]  🚀 Starting + registering on localhost:$PHPFPM"
  launchctl unload -w $PLIST_PATH
  launchctl load -w $PLIST_PATH

  #echo "[$PHP]  🚀 Starting + registering on localhost:$XPHPFPM with xdebug"
  launchctl unload -w $XPLIST_PATH
  launchctl load -w $XPLIST_PATH
}

echo "
🧼 Cleaning MacOS
"

for PHP in $PHPS; do
  remove_php "$PHP"
done

echo "
Installing mysql-client, gnu-sed, pv, jq
"
brew install gnu-sed mysql-client pv jq &>/dev/null &
spinner

brew link mysql-client --force &
spinner

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

echo "pid     err    name
"
launchctl list | grep reach

echo "
🎉 Done"
