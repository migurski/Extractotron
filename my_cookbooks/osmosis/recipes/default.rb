package('openjdk-7-jre-headless')

bash "install osmosis" do
	not_if("which /usr/local/bin/osmosis")

	code <<-CREATE
	    curl -s http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-0.43-RELEASE.tgz | tar -C /usr/local -xzvf -
	CREATE
end

bash "install mapwriter" do
	not_if("file /usr/local/lib/default/mapsforge-map-writer.jar")

	code <<-CREATE
        curl -L http://ci.mapsforge.org/job/mapsforge/lastSuccessfulBuild/artifact/mapsforge-map-writer/target/mapsforge-map-writer-0.3.1-SNAPSHOT-jar-with-dependencies.jar \
             -o /usr/local/lib/default/mapsforge-map-writer.jar
	CREATE
end
