package('openjdk-7-jre-headless')

bash "install osmosis" do
	not_if("find /usr/local/bin -maxdepth 1 -name osmosis")

	code <<-CREATE
	    curl -s http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-0.43-RELEASE.tgz | tar -C /usr/local -xzvf -
	CREATE
end

bash "install mapwriter" do
	not_if("find /usr/local/lib/default -maxdepth 1 -name mapsforge-map-writer-0.3.1-SNAPSHOT-jar-with-dependencies.jar")

	code <<-CREATE
        curl -L http://ci.mapsforge.org/job/mapsforge/lastSuccessfulBuild/artifact/mapsforge-map-writer/target/mapsforge-map-writer-0.3.1-SNAPSHOT-jar-with-dependencies.jar \
             -o /usr/local/lib/default/mapsforge-map-writer-0.3.1-SNAPSHOT-jar-with-dependencies.jar
	CREATE
end
