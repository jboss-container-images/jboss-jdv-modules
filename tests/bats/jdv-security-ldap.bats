#!/usr/bin/env bats

load jdv-common

export JBOSS_HOME=$BATS_TMPDIR/jboss_home
mkdir -p $JBOSS_HOME/standalone/configuration
mkdir -p $JBOSS_HOME/bin/launch

export CONFIG_FILE=$JBOSS_HOME/standalone/configuration/standalone-openshift.xml

source $BATS_TEST_DIRNAME/../../added/launch/security-ldap.sh

setup() {
  cp $BATS_TEST_DIRNAME/resources/standalone-openshift.xml $CONFIG_FILE
  run unset_security_ldap_env
}

@test "do not replace placeholder when URL is not provided" {
    JDV_AUTH_LDAP_ALLOW_EMPTY_PWD="test JDV_AUTH_LDAP_ALLOW_EMPTY_PWD"
    JDV_AUTH_LDAP_BASE_DN="test JDV_AUTH_LDAP_BASE_DN"
    JDV_AUTH_LDAP_BASE_FILTER="test JDV_AUTH_LDAP_BASE_FILTER"
    JDV_AUTH_LDAP_BIND_DN="test JDV_AUTH_LDAP_BIND_DN"
    JDV_AUTH_LDAP_BIND_PWD="test JDV_AUTH_LDAP_BIND_PWD"
    JDV_AUTH_LDAP_ROLE_ATTR_ID="test JDV_AUTH_LDAP_ROLE_ATTR_ID"
    JDV_AUTH_LDAP_ROLE_ATTR_IS_DN="test JDV_AUTH_LDAP_ROLE_ATTR_IS_DN"
    JDV_AUTH_LDAP_ROLE_DN="test JDV_AUTH_LDAP_ROLE_DN"
    JDV_AUTH_LDAP_ROLE_FILTER="test JDV_AUTH_LDAP_ROLE_FILTER"
    JDV_AUTH_LDAP_ROLE_NAME_ATTR_ID="test JDV_AUTH_LDAP_ROLE_NAME_ATTR_ID"
    JDV_AUTH_LDAP_SEARCH_SCOPE="test JDV_AUTH_LDAP_SEARCH_SCOPE"

    run configure_ldap_security_domain

    [ "$output" = "[INFO]JDV_AUTH_LDAP_URL not set. Skipping LDAP integration..." ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-untouched.xml
}

@test "replace placeholder by minimum xml content when URL is provided" {
    JDV_AUTH_LDAP_URL="test_url"

    run configure_ldap_security_domain

    [ "$output" = "[INFO]JDV_AUTH_LDAP_URL is set to test_url. Added LdapExtended login-module" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-url.xml
}

@test "replace placeholder by all LDAP values when provided" {
    JDV_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS="test JDV_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS"
    JDV_AUTH_LDAP_BASE_CTX_DN="test JDV_AUTH_LDAP_BASE_CTX_DN"
    JDV_AUTH_LDAP_BASE_FILTER="test JDV_AUTH_LDAP_BASE_FILTER"
    JDV_AUTH_LDAP_BIND_CREDENTIAL="test JDV_AUTH_LDAP_BIND_CREDENTIAL"
    JDV_AUTH_LDAP_BIND_DN="test JDV_AUTH_LDAP_BIND_DN"
    JDV_AUTH_LDAP_DEFAULT_ROLE="test JDV_AUTH_LDAP_DEFAULT_ROLE"
    JDV_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE="test JDV_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE"
    JDV_AUTH_LDAP_JAAS_SECURITY_DOMAIN="test JDV_AUTH_LDAP_JAAS_SECURITY_DOMAIN"
    JDV_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN="test JDV_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN"
    JDV_AUTH_LDAP_PARSE_USERNAME="test JDV_AUTH_LDAP_PARSE_USERNAME"
    JDV_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK="test JDV_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK"
    JDV_AUTH_LDAP_ROLE_ATTRIBUTE_ID="test JDV_AUTH_LDAP_ROLE_ATTRIBUTE_ID"
    JDV_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN="test JDV_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN"
    JDV_AUTH_LDAP_ROLE_FILTER="test JDV_AUTH_LDAP_ROLE_FILTER"
    JDV_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID="test JDV_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID"
    JDV_AUTH_LDAP_ROLE_RECURSION="test JDV_AUTH_LDAP_ROLE_RECURSION"
    JDV_AUTH_LDAP_ROLES_CTX_DN="test JDV_AUTH_LDAP_ROLES_CTX_DN"
    JDV_AUTH_LDAP_SEARCH_SCOPE="test JDV_AUTH_LDAP_SEARCH_SCOPE"
    JDV_AUTH_LDAP_SEARCH_TIME_LIMIT="test JDV_AUTH_LDAP_SEARCH_TIME_LIMIT"
    JDV_AUTH_LDAP_URL="test JDV_AUTH_LDAP_URL"
    JDV_AUTH_LDAP_USERNAME_BEGIN_STRING="test JDV_AUTH_LDAP_USERNAME_BEGIN_STRING"
    JDV_AUTH_LDAP_USERNAME_END_STRING="test JDV_AUTH_LDAP_USERNAME_END_STRING"

    run configure_ldap_security_domain

    [ "$output" = "[INFO]JDV_AUTH_LDAP_URL is set to test JDV_AUTH_LDAP_URL. Added LdapExtended login-module" ]
    [ "$status" -eq 0 ]
    assert_xml $CONFIG_FILE $BATS_TEST_DIRNAME/expectations/standalone-openshift-ldap-all.xml
}
