#
# Create status-keeping files for Extractotron.
#
directory '/var/run/extractotron' do
    mode   00755
    action :create
    owner  node['user']
end

file '/var/run/extractotron/lock' do
    mode   00666
    action :create
    owner  node['user']
end
