#
# Python packages needed for extraction process.
#
package 'python-imaging'
package 'python-jinja2'
package 'python-numpy'
package 'python-pika'
package 'python-pip'
package 'python-scipy'

#
# Install sh:
#   http://amoffat.github.io/sh/
#
bash "install python sh" do
	not_if 'python -c "import sh"'
	code   'pip install sh'
end

#
# Install ModestMaps:
#   https://github.com/stamen/modestmaps-py
#
bash "install python ModestMaps" do
	not_if 'python -c "import ModestMaps"'
	code   'pip install ModestMaps'
end
