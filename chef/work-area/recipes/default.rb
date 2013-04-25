#
# Ensure work directory exists with global read/write permissions.
#
# If workdir's parent capacity is under 200GB, attempt to run 'work-area-mkfs'
# recipe, which will use EC2 ephemeral storage to prepare a sufficiently-large
# filesystem for OSM data.
#
workdir = node[:workdir]

lines = `df -m #{File.dirname(workdir)}`.split("\n")
parts = lines[1].split()
space = Integer(parts[3])

if space < 200 * 1024
    include_recipe "work-area-mkfs"

    directory workdir do
        action :create
    end
    
    mount workdir do
        device '/dev/work_device'
        fstype "ext3"
        action :mount
    end
end

directory workdir do
    mode   00777
    action :create
end
