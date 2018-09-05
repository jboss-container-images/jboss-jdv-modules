load ./common/logging

load ./common/xml_utils

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

export CCT_MODULES=$BATS_TEST_DIRNAME/../../../../cct_module

cp $CCT_MODULES/os-logging/added/launch/*.sh $JBOSS_HOME/bin/launch
cp $CCT_MODULES/os-eap-launch/added/launch/*.sh $JBOSS_HOME/bin/launch
cp $CCT_MODULES/os-eap64-launch/added/launch/*.sh $JBOSS_HOME/bin/launch

chmod +x $JBOSS_HOME/bin/launch/*.*

#cp $BATS_TEST_DIRNAME/../../os-datavirt/added/launch/*.sh $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml


function assert_xml() {
  local file=$1
  local expected=$2
  local xml=$(xmllint $file)

  diff -Ew <(echo $xml | xmllint --format -) $expected
}
