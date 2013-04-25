#
# Install Apache 2.0.
#
package 'apache2-mpm-worker'
include_recipe 'work-area'

workdir = node[:workdir]

directory '/var/www' do
    action      :delete
    recursive   true
end

link '/var/www' do
    to "#{workdir}/history"
end
