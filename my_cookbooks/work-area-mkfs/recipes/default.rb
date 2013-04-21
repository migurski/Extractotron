#
# Consolidate EC2 ephemeral storage into one large ext3 filesystem at /dev/work_device.
#
# Fails is EC2 metadata is not availale from http://169.254.169.254/.
#
package 'curl'
package 'mdadm' do
    options '--no-install-recommends'
    action :install
end

ruby_block 'Set up /dev/work_device' do
    not_if('test -b /dev/work_device')

    block do
        base = 'http://169.254.169.254/latest/meta-data'
        
        #
        # Check whether we're even inside EC2.
        #
        if not system "curl --connect-timeout 2 -s #{base}/ > /dev/null"
            raise "We might not be in EC2"
        end
        
        #
        # Collect a list of devices.
        #
        devices = []
        
        `curl -s #{base}/block-device-mapping/`.each_line do |line|
            eph = line[/^(ephemeral\d)\b/, 1]
            
            if eph
                dev = `curl -s #{base}/block-device-mapping/#{eph}`.strip
                
                if system "test -b /dev/#{dev}"
                    devices.push("/dev/#{dev}")
        
                elsif system "test -b /dev/xv#{dev[1,2]}"
                    devices.push("/dev/xv#{dev[1,2]}")
                end
            end
        end
        
        #
        # RAID devices into a single device if necessary.
        #
        devices.each do |device|
            system "umount #{device}"
        end
        
        if devices.length > 1
            system 'mdadm -S /dev/md0'
            system "mdadm --create /dev/md0 --level=0 -n #{devices.length} --run #{devices.join(' ')}"
            system 'ln -svf /dev/md0 /dev/work_device'
        
        elsif devices.length == 1
            system "ln -svf #{devices[0]} /dev/work_device"
        
        end
        
        #
        # Make an ext3 file system on the work device.
        #
        system 'mkfs.ext3 -T largefile /dev/work_device'
    end
end
