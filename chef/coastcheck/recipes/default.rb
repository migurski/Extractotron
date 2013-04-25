#
# Install Martijn van Oosterhout's coastline error checker.
#
# Places coast2shp and other executables in /usr/loca/bin, with source
# code from http://svn.openstreetmap.org/applications/utils/coastcheck
#
package 'build-essential'
package 'libbz2-dev'
package 'libproj-dev'
package 'libshp-dev'
package 'libxml2-dev'
package 'subversion'
package 'zlib1g-dev'

bash "install coastcheck" do
	not_if('which osm2coast merge-coastlines.pl coast2shp closeshp')

	code <<-INSTALL
	    PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Tree::R'
	    PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Bit::Vector'
	    
	    DIR=`mktemp -d`
	    svn co http://svn.openstreetmap.org/applications/utils/coastcheck $DIR

	    cd $DIR
	    make

        ln $DIR/osm2coast /usr/local/bin/
        ln $DIR/merge-coastlines.pl /usr/local/bin/
        ln $DIR/coast2shp /usr/local/bin/
        ln $DIR/closeshp /usr/local/bin/
        
        rm -rf $DIR
	INSTALL
end
