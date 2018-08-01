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
    run prepareEnv

    run configure

    echo "$output"

#    [ "$output" = "[INFO] Security domain used for OData transport is teiid-security" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-teiid-default-security-domain.xml
}

@test "configure using env file" {
    cp $BATS_TEST_DIRNAME/resources/standalone-openshift-security-domain.xml $CONFIG_FILE

     run prepareEnv

    RUN_ENV="$BATS_TEST_DIRNAME/securitydomain.env"
    . "$RUN_ENV"   
 
     echo "Security domain $SECURITY_DOMAINS"
    echo "$output"     
     
     run configure


#    [ "$output" = "[INFO] Security domain used for OData transport is teiid-security" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-url.xml
   
}

