#
# Create cron file for periodic running run-queue.py
#
include_recipe 'python'
include_recipe 'status-files'

file '/etc/cron.d/run-queue' do
    mode   00644
    action :create
    user   'root'
    content <<-CRON
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

* * * * *	#{node['user']}	/usr/local/extractotron/run-queue.py
CRON
end
