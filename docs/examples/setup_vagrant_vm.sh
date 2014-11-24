#!/bin/bash
apt-get update
apt-get install curl vim -y
cp -p /vagrant/register_with_api.sh /usr/local/bin/.

cat > /etc/rc.local <<"EOP"
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
/bin/bash /usr/local/bin/register_with_api.sh
exit 0
EOP
