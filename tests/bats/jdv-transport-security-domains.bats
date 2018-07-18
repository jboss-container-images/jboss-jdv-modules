#!/usr/bin/env bats

load jdv-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

cp $BATS_TEST_DIRNAME/../../os-datavirt/added/launch/*.sh $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $JBOSS_HOME/bin/launch/security-domains.sh

@test "replace transport security domain placeholder with testSecurityDomain" {
    cp $BATS_TEST_DIRNAME/resources/standalone-transport-security-domains.xml $CONFIG_FILE
    run unset_security_domains_env

    DEFAULT_SECURITY_DOMAIN="testSecurityDomain"

#    run configure_domains
    run set_transport_security_domains

    echo domain ${DEFAULT_SECURITY_DOMAIN}

    [ "$output" = "[INFO]security domain is ${DEFAULT_SECURITY_DOMAIN}" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-transport-security-domains.xml
}

