#
# Install RabbitMQ server and shared object for downstream packages.
#
# Due to version conflicts in PHP amqp PECL package installation,
# librabbit is installed from source below based on this answer:
#
#   http://stackoverflow.com/questions/9520914/installing-amqp-through-pecl#answer-14459813
#
package 'rabbitmq-server'

package 'git'
package 'build-essential'

bash 'install librabbit' do
    not_if 'file /usr/local/lib/librabbitmq.so'
    
    code <<-INSTALL
        DIR=`mktemp -d /tmp/rabbitmq-XXX`
    
        git clone git://github.com/alanxz/rabbitmq-c.git $DIR
        cd $DIR
        git submodule init
        git submodule update

        autoreconf -i && ./configure && make && make install
        
        rm -rf $DIR
    INSTALL
end
