package('build-essential')
package('libgeos-c1')
package('libprotobuf-dev')
package('libtokyocabinet-dev')
package('protobuf-compiler')
package('python-dev')
package('python-pip')
package('python-psycopg2')
package('python-shapely')

bash "install imposm" do
	not_if('which imposm')

	code <<-INSTALL
	    pip install imposm.parser imposm
	INSTALL
end
