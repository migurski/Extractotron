#
# Install sh:
#   http://amoffat.github.io/sh/
#
package 'python-pip'

bash "install python sh" do
	not_if 'python -c "import sh"'
	code   'pip install sh'
end
