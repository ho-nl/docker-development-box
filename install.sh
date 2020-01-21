#!/bin/bash

PHPS='7.2 7.3 7.4'

spinner()
{
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
    
    echo "🛑 Stopping php-fpm@$PHP"
    brew services stop "php@$PHP" &> /dev/null & spinner

    brew unlink "php@$PHP" > /dev/null & spinner

    echo "🗑  Uninstalling php@$PHP"
    brew uninstall "php@$PHP" > /dev/null & spinner
    rm -rf /usr/local/etc/php/"$PHP";
}

install_php() {
    PHP=$1
    PHPFPM=90${PHP//.}
    XPHPFPM=91${PHP//.}

    echo "👷‍♀️ Installing php@$PHP"
    brew install "php@$PHP" > /dev/null & spinner
    
    echo "⚡️ Configuring generous memory settings"
    sed -i '' 's/^memory_limit.*/memory_limit = 4096M/g' /usr/local/etc/php/"$PHP"/php.ini
    sed -i '' 's/^;opcache.memory_consumption=128/opcache.memory_consumption=512/g' /usr/local/etc/php/"$PHP"/php.ini
    sed -i '' 's/^;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=24/g' /usr/local/etc/php/"$PHP"/php.ini
    sed -i '' 's/^;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g' /usr/local/etc/php/"$PHP"/php.ini
    sed -i '' 's/^;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=130986/g' /usr/local/etc/php/"$PHP"/php.ini
    
    sed -i '' "s/^listen = 127.0.0.1:9000/listen = 127.0.0.1:$PHPFPM/g" /usr/local/etc/php/"$PHP"/php-fpm.d/www.conf
    sed -i '' 's/^pm = dynamic/pm = ondemand/g' /usr/local/etc/php/"$PHP"/php-fpm.d/www.conf
    sed -i '' 's/^pm.max_children = 5/pm.max_children = 20/g' /usr/local/etc/php/"$PHP"/php-fpm.d/www.conf
    sed -i '' 's/^;pm.process_idle_timeout = 10s;/pm.process_idle_timeout = 10s;/g' /usr/local/etc/php/"$PHP"/php-fpm.d/www.conf

    echo "🏗  Installing xdebug"
    /usr/local/opt/php@"$PHP"/bin/pecl install xdebug > /dev/null & spinner

    sed -i '' 's/^zend_extension="xdebug.so"//g' /usr/local/etc/php/"$PHP"/php.ini
    
    cp /usr/local/etc/php/"$PHP"/php-fpm.d/www.conf /usr/local/etc/php/"$PHP"/php-fpm.d/xdebug.conf
    sed -i '' "s/^listen = 127.0.0.1:$PHPFPM/listen = 127.0.0.1:$XPHPFPM/g" /usr/local/etc/php/"$PHP"/php-fpm.d/xdebug.conf
    sed -i '' 's/^zend_extension="xdebug.so"//g' /usr/local/etc/php/"$PHP"/php-fpm.d/xdebug.conf

    echo "✅ Installed php@$PHP";
}

start_php() {
    PHP=$1
    PHPFPM=90${PHP//.}
    XPHPFPM=91${PHP//.}

    echo "🚀  Starting + registering php@$PHP on localhost:$PHPFPM (xdebug: localhost:$XPHPFPM)"
    brew services start php@"$PHP" > /dev/null & spinner
}

echo "
🧼 Cleaning MacOS
"

for PHP in $PHPS;do
    remove_php "$PHP"
done;

echo "
🐘 Installing php services
"

for PHP in $PHPS;do
    install_php "$PHP"
done;

echo "
💅 Starting services
"

for PHP in $PHPS;do
    start_php "$PHP"
done;

echo "
🎉 Done. R Ξ Λ C H  Digital"
