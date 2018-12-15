# 1. Clone the source code from ONOS Gerrit repository
git clone https://gerrit.onosproject.org/onos

# 2. Change the directory into onos
cd onos

# 3. Add ONOS environment to your bash profile
cat << EOF >> ~/.bashrc
export ONOS_ROOT="`pwd`"
source $ONOS_ROOT/tools/dev/bash_profile
EOF
. ~/.bashrc

# 4. Make sure your current directory is onos
# 5. Build ONOS with Bazel
bazel build onos