#
# Python packages needed for extraction process.
#
package 'python-pip'
package 'python-scipy'
package 'python-numpy'
package 'python-jinja2'

#
# Install sh:
#   http://amoffat.github.io/sh/
#
bash "install python sh" do
	not_if 'python -c "import sh"'
	code   'pip install sh'
end
