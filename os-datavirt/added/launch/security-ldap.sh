#!/bin/bash

########## Environment Variables ##########

function unset_security_ldap_env() {
    # please keep these in alphabetical order
    unset JDV_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS
    unset JDV_AUTH_LDAP_BASE_CTX_DN
    unset JDV_AUTH_LDAP_BASE_FILTER
    unset JDV_AUTH_LDAP_BIND_CREDENTIAL
    unset JDV_AUTH_LDAP_BIND_DN
    unset JDV_AUTH_LDAP_DEFAULT_ROLE
    unset JDV_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE
    unset JDV_AUTH_LDAP_JAAS_SECURITY_DOMAIN
    unset JDV_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN
    unset JDV_AUTH_LDAP_PARSE_USERNAME
    unset JDV_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK
    unset JDV_AUTH_LDAP_ROLE_ATTRIBUTE_ID
    unset JDV_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN
    unset JDV_AUTH_LDAP_ROLE_FILTER
    unset JDV_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID
    unset JDV_AUTH_LDAP_ROLE_RECURSION
    unset JDV_AUTH_LDAP_ROLES_CTX_DN
    unset JDV_AUTH_LDAP_SEARCH_SCOPE
    unset JDV_AUTH_LDAP_SEARCH_TIME_LIMIT
    unset JDV_AUTH_LDAP_URL
    unset JDV_AUTH_LDAP_USERNAME_BEGIN_STRING
    unset JDV_AUTH_LDAP_USERNAME_END_STRING
}

function add_module() {
    local xml=$1
    local name=$2
    local envVar=$3

    if [[ ! -z ${envVar} ]]; then
        echo ${xml} '<module-option name="'${name}'" value="'${envVar}'"/>'
    else
        echo ${xml}
    fi
}

function configure_ldap_security_domain() {
    if [[ -z ${JDV_AUTH_LDAP_URL} ]]; then
        log_info "JDV_AUTH_LDAP_URL not set. Skipping LDAP integration..."
        return
    fi
    log_info "JDV_AUTH_LDAP_URL is set to ${JDV_AUTH_LDAP_URL}. Added LdapExtended login-module"
    local security_domain='<login-module code="LdapExtended" flag="required">'

    security_domain=$(add_module "$security_domain" "java.naming.provider.url" "${JDV_AUTH_LDAP_URL}") 
    security_domain=$(add_module "$security_domain" "jaasSecurityDomain" "${JDV_AUTH_LDAP_JAAS_SECURITY_DOMAIN}") 
    security_domain=$(add_module "$security_domain" "bindDN" "${JDV_AUTH_LDAP_BIND_DN}") 
    security_domain=$(add_module "$security_domain" "bindCredential" "${JDV_AUTH_LDAP_BIND_CREDENTIAL}") 
    security_domain=$(add_module "$security_domain" "baseCtxDN" "${JDV_AUTH_LDAP_BASE_CTX_DN}") 
    security_domain=$(add_module "$security_domain" "baseFilter" "${JDV_AUTH_LDAP_BASE_FILTER}")
    security_domain=$(add_module "$security_domain" "rolesCtxDN" "${JDV_AUTH_LDAP_ROLES_CTX_DN}") 
    security_domain=$(add_module "$security_domain" "roleFilter" "${JDV_AUTH_LDAP_ROLE_FILTER}")
    security_domain=$(add_module "$security_domain" "roleAttributeID" "${JDV_AUTH_LDAP_ROLE_ATTRIBUTE_ID}")
    security_domain=$(add_module "$security_domain" "roleAttributeIsDN" "${JDV_AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN}")
    security_domain=$(add_module "$security_domain" "roleNameAttributeID" "${JDV_AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID}")
    security_domain=$(add_module "$security_domain" "defaultRole" "${JDV_AUTH_LDAP_DEFAULT_ROLE}")
    security_domain=$(add_module "$security_domain" "roleRecursion" "${JDV_AUTH_LDAP_ROLE_RECURSION}")
    security_domain=$(add_module "$security_domain" "distinguishedNameAttribute" "${JDV_AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE}")
    security_domain=$(add_module "$security_domain" "parseRoleNameFromDN" "${JDV_AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN}")
    security_domain=$(add_module "$security_domain" "parseUsername" "${JDV_AUTH_LDAP_PARSE_USERNAME}")
    security_domain=$(add_module "$security_domain" "usernameBeginString" "${JDV_AUTH_LDAP_USERNAME_BEGIN_STRING}")
    security_domain=$(add_module "$security_domain" "usernameEndString" "${JDV_AUTH_LDAP_USERNAME_END_STRING}")
    security_domain=$(add_module "$security_domain" "searchTimeLimit" "${JDV_AUTH_LDAP_SEARCH_TIME_LIMIT}")
    security_domain=$(add_module "$security_domain" "searchScope" "${JDV_AUTH_LDAP_SEARCH_SCOPE}")
    security_domain=$(add_module "$security_domain" "allowEmptyPasswords" "${JDV_AUTH_LDAP_ALLOW_EMPTY_PASSWORDS}")
    security_domain=$(add_module "$security_domain" "referralUserAttributeIDToCheck" "${JDV_AUTH_LDAP_REFERRAL_USER_ATTRIBUTE_ID_TO_CHECK}") 
    
    security_domain="${security_domain}"'</login-module><!-- ##OTHER_LOGIN_MODULES## -->'

    sed -i "s|<!-- ##OTHER_LOGIN_MODULES## -->|${security_domain}|" "${CONFIG_FILE}"
}
