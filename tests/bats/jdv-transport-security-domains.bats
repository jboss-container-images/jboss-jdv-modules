#!/usr/bin/env bats

load jdv-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

export CCT_MODULES=$BATS_TEST_DIRNAME/../../../../cct_module

cp $CCT_MODULES/os-logging/added/launch/*.sh $JBOSS_HOME/bin/launch
cp $CCT_MODULES/os-eap-launch/added/launch/*.sh $JBOSS_HOME/bin/launch
cp $CCT_MODULES/os-eap64-launch/added/launch/*.sh $JBOSS_HOME/bin/launch
cp $BATS_TEST_DIRNAME/../../os-datavirt/added/launch/*.sh $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $JBOSS_HOME/bin/launch/security-domains.sh

@test "replace transport security domain placeholder with testSecurityDomain" {
    cp $BATS_TEST_DIRNAME/resources/standalone-transport-security-domains.xml $CONFIG_FILE

    DEFAULT_SECURITY_DOMAIN="testSecurityDomain"

    run preConfigure
    run configure

    run preConfigureEnv
    run configureEnv

    run postConfigure


 #   [ "$output" = "[INFO]Security domain used for OData transport is testSecurityDomain" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-transport-security-domains.xml
}

@test "replace secure transport placeholder" {
    cp $BATS_TEST_DIRNAME/resources/standalone-transport-security-domains.xml $CONFIG_FILE

    RUN_ENV="$BATS_TEST_DIRNAME/transport.env"
    . "$RUN_ENV"   

    run preConfigure
    run configure

    run preConfigureEnv
    run configureEnv

    run postConfigure


 #   [ "$output" = "[INFO]Security domain used for OData transport is testSecurityDomain" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-secure-transport.xml
}
