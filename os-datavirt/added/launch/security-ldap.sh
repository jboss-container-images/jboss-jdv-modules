#!/bin/bash

########## Environment Variables ##########

function unset_security_ldap_env() {
    # please keep these in alphabetical order
    unset AUTH_LDAP_ALLOW_EMPTY_PASSWORDS
    unset AUTH_LDAP_AUTHENTICATION
    unset AUTH_LDAP_BASE_CTX_DN
    unset AUTH_LDAP_BASE_FILTER
    unset AUTH_LDAP_BIND_CREDENTIAL
    unset AUTH_LDAP_BIND_DN
    unset AUTH_LDAP_CREDENTIALS
    unset AUTH_LDAP_DEFAULT_ROLE
    unset AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE
    unset AUTH_LDAP_FACTORY
    unset AUTH_LDAP_JAAS_SECURITY_DOMAIN
    unset AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN
    unset AUTH_LDAP_PARSE_USERNAME
    unset AUTH_LDAP_PRINCIPAL
    unset AUTH_LDAP_PROTOCOL
    unset AUTH_LDAP_USER_ATTRIBUTE_ID_TO_CHECK
    unset AUTH_LDAP_ROLE_ATTRIBUTE_ID
    unset AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN
    unset AUTH_LDAP_ROLE_FILTER
    unset AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID
    unset AUTH_LDAP_ROLE_RECURSION
    unset AUTH_LDAP_ROLES_CTX_DN
    unset AUTH_LDAP_SEARCH_SCOPE
    unset AUTH_LDAP_SEARCH_TIME_LIMIT
    unset AUTH_LDAP_URL
    unset AUTH_LDAP_USERNAME_BEGIN_STRING
    unset AUTH_LDAP_USERNAME_END_STRING
    unset AUTH_LDAP_THROW_VALIDATE_ERROR
    
    unset DEFAULT_SECURITY_DOMAIN
}

function add_module() {
    local xml=$1
    local name=$2
    local envVar=$3

    if [[ ! -z ${envVar} ]]; then
        echo "${xml} \ 
                    <module-option name=\"${name}\" value=\"${envVar}\"/>"
    else
        echo ${xml}
    fi
}

function configure_ldap_security_domain() {
    if [[ -z ${AUTH_LDAP_URL} ]]; then
        log_info "AUTH_LDAP_URL not set. Skipping LDAP integration..."
        return
    fi
     
    local security_domain="\
                    <security-domain name=\"${DEFAULT_SECURITY_DOMAIN:-teiid-security}\" cache-type=\"default\">\
                        <authentication>\
                            <login-module code=\"LdapExtended\" flag=\"required\">"

    security_domain=$(add_module "$security_domain" "java.naming.provider.url" "${AUTH_LDAP_URL}") 

     # default com.sun.jndi.ldap.LdapCtxFactory
    security_domain=$(add_module "$security_domain" "java.naming.factory.initial" "${AUTH_LDAP_FACTORY:-com.sun.jndi.ldap.LdapCtxFactory}") 
     
    # default simple
    security_domain=$(add_module "$security_domain" "java.naming.security.authentication" "${AUTH_LDAP_AUTHENTICATION:-simple}")
     
    security_domain=$(add_module "$security_domain" "java.naming.security.protocol"  "${AUTH_LDAP_PROTOCOL}") 
    security_domain=$(add_module "$security_domain" "java.naming.security.principal" "${AUTH_LDAP_PRINCIPAL}") 
    security_domain=$(add_module "$security_domain" "java.naming.security.credentials" "${AUTH_LDAP_CREDENTIALS}") 
    security_domain=$(add_module "$security_domain" "jaasSecurityDomain"              "${AUTH_LDAP_JAAS_SECURITY_DOMAIN}")
    
    security_domain=$(add_module "$security_domain" "bindDN"                         "${AUTH_LDAP_BIND_DN}") 
    security_domain=$(add_module "$security_domain" "bindCredential"                 "${AUTH_LDAP_BIND_CREDENTIAL}") 
    security_domain=$(add_module "$security_domain" "baseCtxDN"                      "${AUTH_LDAP_BASE_CTX_DN}") 
    security_domain=$(add_module "$security_domain" "baseFilter"                     "${AUTH_LDAP_BASE_FILTER}")
    security_domain=$(add_module "$security_domain" "rolesCtxDN"                     "${AUTH_LDAP_ROLES_CTX_DN}") 
    security_domain=$(add_module "$security_domain" "roleFilter"                     "${AUTH_LDAP_ROLE_FILTER}")
    security_domain=$(add_module "$security_domain" "roleAttributeID"                "${AUTH_LDAP_ROLE_ATTRIBUTE_ID}")
    security_domain=$(add_module "$security_domain" "searchScope"                    "${AUTH_LDAP_SEARCH_SCOPE:-SUBTREE_SCOPE}")
    security_domain=$(add_module "$security_domain" "roleAttributeIsDN"              "${AUTH_LDAP_ROLE_ATTRIBUTE_IS_DN:-false}")
    security_domain=$(add_module "$security_domain" "parseRoleNameFromDN"            "${AUTH_LDAP_PARSE_ROLE_NAME_FROM_DN:-false}")
    security_domain=$(add_module "$security_domain" "parseUsername"                  "${AUTH_LDAP_PARSE_USERNAME:-false}")
    security_domain=$(add_module "$security_domain" "searchTimeLimit"                "${AUTH_LDAP_SEARCH_TIME_LIMIT:-10000}")
    security_domain=$(add_module "$security_domain" "allowEmptyPasswords"            "${AUTH_LDAP_ALLOW_EMPTY_PASSWORDS:-false}")
    security_domain=$(add_module "$security_domain" "throwValidateError"             "${AUTH_LDAP_THROW_VALIDATE_ERROR:-false}")

    security_domain=$(add_module "$security_domain" "roleNameAttributeID"            "${AUTH_LDAP_ROLE_NAME_ATTRIBUTE_ID}")
    security_domain=$(add_module "$security_domain" "defaultRole"                    "${AUTH_LDAP_DEFAULT_ROLE}")
    security_domain=$(add_module "$security_domain" "roleRecursion"                  "${AUTH_LDAP_ROLE_RECURSION}")
    security_domain=$(add_module "$security_domain" "distinguishedNameAttribute"     "${AUTH_LDAP_DISTINGUISHED_NAME_ATTRIBUTE}")
    security_domain=$(add_module "$security_domain" "usernameBeginString"            "${AUTH_LDAP_USERNAME_BEGIN_STRING}")
    security_domain=$(add_module "$security_domain" "usernameEndString"              "${AUTH_LDAP_USERNAME_END_STRING}")
    security_domain=$(add_module "$security_domain" "referralUserAttributeIDToCheck" "${AUTH_LDAP_USER_ATTRIBUTE_ID_TO_CHECK}") 
     
    security_domain="$security_domain \
                                    </login-module>\
                                </authentication>\
                            </security-domain>"
    
    sed -i "s|<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|${security_domain}<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|" "$CONFIG_FILE"
    
    log_info "AUTH_LDAP_URL is set to ${AUTH_LDAP_URL}. Added LdapExtended login-module"
}
