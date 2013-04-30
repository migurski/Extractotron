#
# Install Apache, PHP and packages needed to support web views.
#
package 'apache2-mpm-prefork'
package 'libapache2-mod-php5'
package 'php-pear'

include_recipe 'rabbitmq'

bash 'install amqp extension' do
    creates '/usr/lib/php5/20090626/amqp.so'
    code 'pecl install -f http://pecl.php.net/get/amqp-1.0.10.tgz'
end

bash 'enable amqp extension' do
    not_if 'grep amqp.so /etc/php5/apache2/php.ini'

    code <<-ENABLE
        echo ''                  >> /etc/php5/apache2/php.ini
        echo '; Added by chef.'  >> /etc/php5/apache2/php.ini
        echo 'extension=amqp.so' >> /etc/php5/apache2/php.ini
    ENABLE
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

execute 'apache2ctl restart' do
    path ['/usr/bin', '/usr/sbin', '/usr/local/bin', '/usr/local/sbin']
end
