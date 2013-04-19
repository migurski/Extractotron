package('postgresql-9.1-postgis')

bash "create database" do
	not_if("psql -c '\\l' | egrep '^\s*ubuntu'", :user=>'postgres')

	user "postgres"
	code <<-CREATE
		createuser -SLRD ubuntu
		createdb -O ubuntu ubuntu

		psql -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql ubuntu
		psql -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql ubuntu

		psql -c 'ALTER TABLE geography_columns OWNER TO ubuntu' ubuntu
		psql -c 'ALTER TABLE geometry_columns OWNER TO ubuntu' ubuntu
		psql -c 'ALTER TABLE spatial_ref_sys OWNER TO ubuntu' ubuntu
	CREATE
end
