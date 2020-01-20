PHPS='7.2 7.3 7.4'
for PHP in $PHPS;do

    echo "♻️  Setting up brew php@$PHP"

    echo "🛑 Stopping php-fpm"
    brew services stop php@$PHP

    echo "🗑  Removing old php configuration"
    rm -rf /usr/local/etc/php/$PHP

    brew reinstall php@$PHP

    echo "🏃‍♀️💨 Configuring php M2 defaults"
    sed -i '' 's/^memory_limit.*/memory_limit = 4096M/g' /usr/local/etc/php/$PHP/php.ini
    sed -i '' 's/^;opcache.memory_consumption=128/opcache.memory_consumption=512/g' /usr/local/etc/php/$PHP/php.ini
    sed -i '' 's/^;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=24/g' /usr/local/etc/php/$PHP/php.ini
    sed -i '' 's/^;opcache.revalidate_freq=2/opcache.revalidate_freq=0/g' /usr/local/etc/php/$PHP/php.ini
    sed -i '' 's/^;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=130986/g' /usr/local/etc/php/$PHP/php.ini

    PHPFPM=90${PHP//.}
    sed -i '' "s/^listen = 127.0.0.1:9000/listen = 127.0.0.1:$PHPFPM/g" /usr/local/etc/php/$PHP/php-fpm.d/www.conf
    sed -i '' 's/^pm = dynamic/pm = ondemand/g' /usr/local/etc/php/$PHP/php-fpm.d/www.conf
    sed -i '' 's/^pm.max_children = 5/pm.max_children = 20/g' /usr/local/etc/php/$PHP/php-fpm.d/www.conf
    sed -i '' 's/^;pm.process_idle_timeout = 10s;/pm.process_idle_timeout = 10s;/g' /usr/local/etc/php/$PHP/php-fpm.d/www.conf

    echo "🚀  Launching php@$PHP fpm service on localhost:$PHPFPM"
    brew services start php@$PHP

    echo "✅ Setting up php@$PHP is done:"
done

brew services list
