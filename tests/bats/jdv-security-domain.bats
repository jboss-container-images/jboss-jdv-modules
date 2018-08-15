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


@test "configure default teiid security domain" {
    cp $BATS_TEST_DIRNAME/resources/standalone-openshift.xml $CONFIG_FILE

     run preConfigure

export  USE_DEFAULT_SECURITY_DOMAIN="true"
    run configure

    run postConfigure

    echo "$output"

#    [ "$output" = "[INFO] Security domain used for OData transport is teiid-security" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-teiid-default-security-domain.xml
}


@test "configure using properties" {
    cp $BATS_TEST_DIRNAME/resources/standalone-openshift-security-domain.xml $CONFIG_FILE

    RUN_ENV="$BATS_TEST_DIRNAME/securitydomain.env"
    . "$RUN_ENV"   

    run preConfigure
    run configure

    run postConfigure

#    [ "$output" = "[INFO] Security domain used for OData transport is teiid-security" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-using-configprops.xml
   
}

@test "configure using env file" {
    cp $BATS_TEST_DIRNAME/resources/standalone-openshift-security-domain.xml $CONFIG_FILE

    run preConfigure
    run configure

    RUN_ENV="$BATS_TEST_DIRNAME/securitydomain.env"
    . "$RUN_ENV"   
 
    run preConfigureEnv
    run configureEnv

    run postConfigure

#    [ "$output" = "[INFO] Security domain used for OData transport is teiid-security" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-using-env.xml
   
}

