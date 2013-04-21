#
# Install Jochen Topf's osmcoastline.
#
# Places osmcoastline and other executables in /usr/loca/bin,
# with source code from https://github.com/joto/osmcoastline/
#
# To use:
#   osmcoastline_filter -o planet-coast.pbf planet.pbf
#   osmcoastline -v -f -o planet-coast.db planet-coast.pbf
#   ogr2ogr -f "ESRI Shapefile" land_polygons.shp planet-coast.db land_polygons
#   ogr2ogr -f "ESRI Shapefile" water_polygons.shp planet-coast.db water_polygons
#
package 'build-essential'
package 'doxygen'
package 'git'
package 'libboost-dev'
package 'libboost-test-dev'
package 'libexpat1-dev'
package 'libgd2-xpm-dev'
package 'libgdal1-dev'
package 'libgeos++-dev'
package 'libicu-dev'
package 'libosmpbf-dev'
package 'libprotobuf-dev'
package 'libshp-dev'
package 'libsparsehash-dev'
package 'libsqlite3-dev'
package 'libv8-dev'
package 'protobuf-compiler'
package 'zlib1g-dev'

bash "install osmcoastline" do
	not_if('which osmcoastline osmcoastline_filter')

	code <<-INSTALL
	    DIR=`mktemp -d`
	    
	    git clone git://github.com/joto/osmium.git $DIR/o
	    cd $DIR/o
	    make install
	    
	    git clone git://github.com/joto/osmcoastline.git $DIR/oc
	    cd $DIR/oc
	    make
	    
	    ln $DIR/oc/osmcoastline /usr/local/bin/
	    ln $DIR/oc/osmcoastline_filter /usr/local/bin/
	    
	    rm -rf $DIR
	INSTALL
end
