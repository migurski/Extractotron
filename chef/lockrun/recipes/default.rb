#
# Install Stephen J. Friedl's lockrun.
#
# Places lockrun executable in /usr/loca/bin, with
# source code from https://github.com/pushcx/lockrun
#
# Originally from http://unixwiz.net/archives/2006/06/new_tool_lockru.html
#
package 'build-essential'
package 'git'

bash "install lockrun" do
	not_if('which lockrun')

	code <<-INSTALL
	    DIR=`mktemp -d`
	    git clone git://github.com/pushcx/lockrun.git $DIR

	    cd $DIR
	    gcc lockrun.c -o lockrun
	    ln lockrun /usr/local/bin/
        
        rm -rf $DIR
	INSTALL
end
