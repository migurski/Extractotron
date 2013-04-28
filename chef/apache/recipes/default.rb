#
# Install Apache, PHP and packages needed to support web views.
#
package 'apache2-mpm-prefork'
package 'libapache2-mod-php5'
package 'php-pear'

include_recipe 'rabbitmq'

bash 'install amqp extension' do
    not_if 'file /usr/lib/php5/*/amqp.so && grep amqp.so /etc/php5/apache2/php.ini'

    code <<-INSTALL
        pecl install -f http://pecl.php.net/get/amqp-1.0.10.tgz

        echo ''                  >> /etc/php5/apache2/php.ini
        echo '; Added by chef.'  >> /etc/php5/apache2/php.ini
        echo 'extension=amqp.so' >> /etc/php5/apache2/php.ini
    INSTALL
end

include_recipe 'work-area'

workdir = node[:workdir]

directory '/var/www' do
    action      :delete
    recursive   true
end

link '/var/www' do
    to "#{workdir}/history"
end

link '/var/www/status.php' do
    to "/usr/local/extractotron/www/status.php"
end

execute 'apache2ctl restart'
