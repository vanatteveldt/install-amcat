PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $PWD/defaults.cfg

echo "Installing basic features."
apt-get install -y curl software-properties-common python-software-properties git python-pip

echo "Checking whether user $AMCAT_USER exists"
# The directory that contains $AMCAT_ROOT will be the user's home directory
getent passwd $AMCAT_USER  > /dev/null
if [ $? -eq 2 ]; then
    echo "Creating user..."
    set -e
    USER_HOME=`dirname $AMCAT_ROOT` 
    useradd -Ms/bin/bash --home "$USER_HOME" $AMCAT_USER
    mkdir -p $USER_HOME
    chown amcat:amcat $USER_HOME
fi
set -e

echo "Create folder $AMCAT_ROOT if needed"
mkdir -p $AMCAT_ROOT
chown amcat:amcat $AMCAT_ROOT
set +e
