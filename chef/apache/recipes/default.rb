#
# Install Apache 2.0.
#
package 'apache2-mpm-prefork'
package 'libapache2-mod-php5'
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
