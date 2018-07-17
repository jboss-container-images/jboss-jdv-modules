#!/usr/bin/env bats

load jdv-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../os-datavirt/added/launch/*.sh $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $JBOSS_HOME/bin/launch/transport-security-domains.sh

setup() {
  cp $BATS_TEST_DIRNAME/resources/standalone-security-domains.xml $CONFIG_FILE
  run unset_security_domains_env
}

@test "replace transport security domain placeholder with default" {
    DEFAULT_SECURITY_DOMAIN="testSecurityDomain"

    run set_transport_security_domains

    cp $CONFIG_FILE $BATS_TEST_DIRNAME/resources/updated-domains.xml

 #   [ "$output" = "[INFO]security domain is testSecurityDomain" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-default-security-domains.xml
}
