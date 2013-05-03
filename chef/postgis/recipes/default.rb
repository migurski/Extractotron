#
# Install Postgres, PostGIS and create a spatial database.
#
# Update permissions and user accounts to trust everyone.
#
package 'postgresql-9.1-postgis'
include_recipe 'work-area'

regexp = 's/^((?:local(?:\s+\S+){2}|host(?:\s+\S+){3})\s+)(\S+)$/\1trust # was: \2/'
username = node[:postgis][:username]
database = node[:postgis][:database]
workdir = node[:workdir]

bash 'open permissions' do
	not_if 'egrep "\btrust # was:" /etc/postgresql/9.1/main/pg_hba.conf'

	user 'root'
	code <<-OPEN
	    perl -pi -e '#{regexp}' /etc/postgresql/9.1/main/pg_hba.conf
	    /etc/init.d/postgresql restart
    OPEN
end

bash 'create tablespace' do
    not_if("psql -U postgres -c \"SELECT spcname FROM pg_tablespace WHERE spcname='work'\" | egrep '^\s*work$'")
    
    user 'postgres'
    code <<-CREATE
        mkdir #{workdir}/postgres
        psql -c "CREATE TABLESPACE work LOCATION '#{workdir}/postgres'"
    CREATE
end

#
# Use createdb -T template0 because imposm will fail with default ASCII encoding:
# http://askubuntu.com/questions/20880/how-do-i-create-a-unicode-databases-in-postgresql-8-4
#
bash "create database" do
	not_if("psql -U postgres -c '\\l' | egrep '^\s*#{database}\s'")

	user 'postgres'
	code <<-CREATE
		createuser -lSRD #{username}
		createdb -D work -E utf-8 -O #{username} -T template0 #{database}

		psql -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql #{database}
		psql -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql #{database}

		psql -c 'ALTER TABLE geography_columns OWNER TO #{username}' #{database}
		psql -c 'ALTER TABLE geometry_columns OWNER TO #{username}' #{database}
		psql -c 'ALTER TABLE spatial_ref_sys OWNER TO #{username}' #{database}
	CREATE
end
