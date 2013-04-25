#
# Install Osmosis and its Mapsforge MapWriter extension.
#
# Use a recent version of Osmosis to account for >32bit entity IDs.
# Mapsforge installation wiki page is out of date, use this:
#
#   http://lists.openstreetmap.org/pipermail/dev/2013-April/026851.html
#   http://lists.openstreetmap.org/pipermail/dev/2013-April/026853.html
#
package 'openjdk-7-jre-headless'

bash 'install osmosis' do
	not_if 'which osmosis'
	code   'curl -s http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-0.43-RELEASE.tgz | tar -C /usr/local -xzvf -'
end

bash 'install mapwriter' do
	not_if 'file /usr/local/lib/default/mapsforge-map-writer.jar'

	code <<-CREATE
        curl -L http://ci.mapsforge.org/job/mapsforge/lastSuccessfulBuild/artifact/mapsforge-map-writer/target/mapsforge-map-writer-0.3.1-SNAPSHOT-jar-with-dependencies.jar \
             -o /usr/local/lib/default/mapsforge-map-writer.jar
	CREATE
end
