source $JBOSS_HOME/bin/launch/launch-common.sh
source $JBOSS_HOME/bin/launch/logging.sh


function clearDomainEnv() {
  local prefix=$1

  unset ${prefix}_LOGIN_MODULE_CODE
  unset ${prefix}_LOGIN_MODULE_MODULE

  for option in $(compgen -v | grep -s "${prefix}_MODULE_OPTION_"); do
    unset ${option}
  done
}

function unset_props() {
  unset SECDOMAIN_NAME
  unset SECDOMAIN_USERS_PROPERTIES
  unset SECDOMAIN_ROLES_PROPERTIES
  unset SECDOMAIN_LOGIN_MODULE
  unset SECDOMAIN_PASSWORD_STACKING
  
    
  for prefix in $(echo $SECURITY_DOMAINS | sed "s/,/ /g"); do
    clearDomainEnv $prefix
  done

}

function preConfigure() {

  unset_props
}


function configure() {

  log_info "Configure from configProps"
  if [ -n "$SECURITY_DOMAINS" ]; then
        log_info "Configure security domains $SECURITY_DOMAINS from configProps"
        configure_domains $SECURITY_DOMAINS
  fi
  
  configure_legacy_security_domains
  
  if [ -n "$JDBC_SECURITY_DOMAIN" ]; then
       # add the secure transport first, so that the property substitution can be done next
        add_secure_transport
        set_transport_security_domains
        
  fi
  
}

function prepareEnv() {
  unset SECURITY_DOMAINS
   
  unset DATAVIRT_TRANSPORT_KEY_ALIAS
  unset DATAVIRT_TRANSPORT_KEYSTORE
  unset DATAVIRT_TRANSPORT_KEYSTORE_PASSWORD
  unset DATAVIRT_TRANSPORT_KEYSTORE_TYPE
  unset DATAVIRT_TRANSPORT_KEYSTORE_DIR
  unset DATAVIRT_TRANSPORT_AUTHENTICATION_MODE
  
  unset JDBC_SECURITY_DOMAIN
  unset ODBC_SECURITY_DOMAIN
  unset ODATA_SECURITY_DOMAIN
  unset DEFAULT_SECURITY_DOMAIN
   
   unset_props
}

function configureEnv() {
  log_info "Configure from ENV_FILES"

  if [ -n "$SECURITY_DOMAINS" ]; then
        log_info "Configure security domains $SECURITY_DOMAINS from ENV_FILES"
        configure_domains $SECURITY_DOMAINS
  fi
  
  if [ -n "$JDBC_SECURITY_DOMAIN" ]; then
       # add the secure transport first, so that the property substitution can be done next
        add_secure_transport
        set_transport_security_domains
  fi
  
}


#  because configureEnv may not be called because there are no ENV_FILES, then the configuration has to be
#  checked in the post processing in order to ensure the default security domain is triggered
function postConfigure() {


# if security domain hasnt been created, then create the default security domain
  
  if [ ! -f "$JBOSS_HOME/secdomaincreated.txt" ]
  then
  
        log_info "Configure default teiid-security domain"
        DEFAULT_SECURITY_DOMAIN=${DEFAULT_SECURITY_DOMAIN:-teiid-security}

        local domain="teiid_security"
        
        JDBC_SECURITY_DOMAIN=$DEFAULT_SECURITY_DOMAIN
        ODBC_SECURITY_DOMAIN=$DEFAULT_SECURITY_DOMAIN
        ODATA_SECURITY_DOMAIN=$DEFAULT_SECURITY_DOMAIN

        teiid_security_SECURITY_DOMAIN_NAME=$DEFAULT_SECURITY_DOMAIN
        teiid_security_SECURITY_DOMAIN_CACHE_TYPE="default"
        teiid_security_SECURITY_DOMAIN_LOGIN_MODULES="realmdirect"

        realmdirect_LOGIN_MODULE_CODE="RealmDirect"
        realmdirect_LOGIN_MODULE_FLAG="sufficient"
        
        realmdirect_MODULE_OPTION_NAME_1="password-stacking"
        realmdirect_MODULE_OPTION_VALUE_1="useFirstPass"
        
        configure_domains $domain  
        add_secure_transport
  fi 

  set_transport_security_domains
    
  # clean up files
  if [ -f "$JBOSS_HOME/secdomaincreated.txt" ]
  then
      rm $JBOSS_HOME/secdomaincreated.txt
  fi
  if [ -f "$JBOSS_HOME/transportcreated.txt" ]
  then
      rm $JBOSS_HOME/transportcreated.txt
  fi
  

}

function configure_domains() {

    local sec_domain=$1

    for domain_prefix in $(echo $sec_domain | sed "s/,/ /g"); do
    
      local security_domain_name=$(find_env ${domain_prefix}_SECURITY_DOMAIN_NAME)
      local security_domain_cache_type=$(find_env ${domain_prefix}_SECURITY_DOMAIN_CACHE_TYPE)
      local security_login_modules=$(find_env ${domain_prefix}_SECURITY_DOMAIN_LOGIN_MODULES)
      
      local security_domain="<security-domain name=\"$security_domain_name\" cache-type=\"$security_domain_cache_type\">"
      
      if [ -n "$security_login_modules" ]; then

        security_domain="$security_domain <authentication>"
      
        for login_module_prefix in $(echo $security_login_modules | sed "s/,/ /g"); do
      
            local login_module_name=$(find_env ${login_module_prefix}_LOGIN_MODULE_NAME)

            
            local login_module_code=$(find_env ${login_module_prefix}_LOGIN_MODULE_CODE)
            local login_module_flag=$(find_env ${login_module_prefix}_LOGIN_MODULE_FLAG)
            local login_module_module=$(find_env ${login_module_prefix}_LOGIN_MODULE_MODULE)
            security_domain="$security_domain <login-module code=\"$login_module_code\" flag=\"$login_module_flag\""
            if [ -n "$login_module_module" ]; then
                security_domain="$security_domain module=\"$login_module_module\""
            fi
            security_domain="$security_domain >"

            local options=$(compgen -v | grep -sE "${login_module_prefix}_MODULE_OPTION_NAME_[a-zA-Z]*(_[a-zA-Z]*)*")
            
            for option in $(echo $options); do
                option_name=$(find_env ${option})
                option_value=$(find_env `sed 's/_NAME_/_VALUE_/' <<< ${option}`)
                if [ -n "$option_value" ]; then
                    security_domain="$security_domain <module-option name=\"$option_name\" value=\"$option_value\"/>"
                fi
            done
            
            security_domain="$security_domain </login-module>"
            
        done
        
        security_domain="$security_domain </authentication></security-domain>"
        sed -i "s|<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|${security_domain}<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|" "$CONFIG_FILE"

      else
      
        log_warning "${domain_prefix} security domain has no login modules defined for property ${domain_prefix}_SECURITY_DOMAIN_LOGIN_MODULES"
        
      fi
      
      touch $JBOSS_HOME/secdomaincreated.txt
       
     done


}

function configure_legacy_security_domains() {
  local usersProperties="\${jboss.server.config.dir}/${SECDOMAIN_USERS_PROPERTIES}"
  local rolesProperties="\${jboss.server.config.dir}/${SECDOMAIN_ROLES_PROPERTIES}"

  # CLOUD-431: Check if provided files are absolute paths
  test "${SECDOMAIN_USERS_PROPERTIES:0:1}" = "/" && usersProperties="${SECDOMAIN_USERS_PROPERTIES}"
  test "${SECDOMAIN_ROLES_PROPERTIES:0:1}" = "/" && rolesProperties="${SECDOMAIN_ROLES_PROPERTIES}"


  if [ -n "$SECDOMAIN_NAME" ]; then
      local domains=""
      local login_module=${SECDOMAIN_LOGIN_MODULE:-UsersRoles}
      local realm=""
      local stack=""

      if [ $login_module == "RealmUsersRoles" ]; then
          realm="<module-option name=\"realm\" value=\"ApplicationRealm\"/>"
      fi

      if [ -n "$SECDOMAIN_PASSWORD_STACKING" ]; then
          stack="<module-option name=\"password-stacking\" value=\"useFirstPass\"/>"
      fi
      domains="\
        <security-domain name=\"$SECDOMAIN_NAME\" cache-type=\"default\">\
            <authentication>\
                <login-module code=\"$login_module\" flag=\"required\">\
                    <module-option name=\"usersProperties\" value=\"${usersProperties}\"/>\
                    <module-option name=\"rolesProperties\" value=\"${rolesProperties}\"/>\
                    $realm\
                    $stack\


                </login-module>\
            </authentication>\
        </security-domain>"
        
        sed -i "s|<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|${domains}<!-- ##ADDITIONAL_SECURITY_DOMAINS## -->|" "$CONFIG_FILE"
  fi


}


function set_transport_security_domains(){
  
  if [ ! -f "$JBOSS_HOME/transportcreated.txt" ]
  then

        sed -i "s|##JDBC_SECURITY_DOMAIN##|${JDBC_SECURITY_DOMAIN:-${DEFAULT_SECURITY_DOMAIN}}|g" ${CONFIG_FILE}
        sed -i "s|##ODBC_SECURITY_DOMAIN##|${ODBC_SECURITY_DOMAIN:-${DEFAULT_SECURITY_DOMAIN}}|g" ${CONFIG_FILE}
        sed -i "s|##ODATA_SECURITY_DOMAIN##|${ODATA_SECURITY_DOMAIN:-${DEFAULT_SECURITY_DOMAIN}}|g" ${CONFIG_FILE}
        
        touch $JBOSS_HOME/transportcreated.txt
        
        RESULT_DOMAIN=${ODATA_SECURITY_DOMAIN:-${DEFAULT_SECURITY_DOMAIN}}
        
        log_info "Security domain used for OData transport is ${RESULT_DOMAIN}"
    fi
}

function add_secure_transport(){
  local key_alias=${DATAVIRT_TRANSPORT_KEY_ALIAS}
  local keystore=${DATAVIRT_TRANSPORT_KEYSTORE:-$HTTPS_KEYSTORE}
  local keystore_pwd=${DATAVIRT_TRANSPORT_KEYSTORE_PASSWORD:-$HTTPS_PASSWORD}
  local keystore_type=${DATAVIRT_TRANSPORT_KEYSTORE_TYPE:-$HTTPS_KEYSTORE_TYPE}
  local keystore_dir=${DATAVIRT_TRANSPORT_KEYSTORE_DIR:-$HTTPS_KEYSTORE_DIR}
  local auth_mode=${DATAVIRT_TRANSPORT_AUTHENTICATION_MODE}
  
  local jdbcsecdomain=${JDBC_SECURITY_DOMAIN:-${DEFAULT_SECURITY_DOMAIN}}
  local odbcsecdomain=${ODBC_SECURITY_DOMAIN:-${DEFAULT_SECURITY_DOMAIN}}

  if [ -n "$key_alias" ] && [ -n "$keystore_pwd" ] && [ -n "$keystore" ] && [ -n "$keystore_dir" ]; then
    if [ -z "$keystore_type" ]; then
      keystore_type="JKS"
    fi

    if [ -z "$auth_mode" ]; then
      auth_mode="1-way"
    fi
  fi

  if [ -n "$auth_mode" ]; then
    if [ "$auth_mode" != "anonymous" ]; then
      if [ -z "$key_alias" ] || [ -z "$keystore_pwd" ] || [ -z "$keystore" ] || [ -z "$keystore_dir" ]; then
        log_warning "Secure JDBC transport missing alias, keystore, key password, and/or keystore directory for authentication mode '$auth_mode'. Will not be enabled"
        return
      fi
    fi

    local transport="<transport name=\"secure-jdbc\" socket-binding=\"secure-teiid-jdbc\" protocol=\"teiid\"><authentication "
        
    transport="$transport security-domain=\"$jdbcsecdomain\"/><ssl mode=\"enabled\" authentication-mode=\"$auth_mode\" ssl-protocol=\"TLSv1.2\" keymanagement-algorithm=\"SunX509\">"
    
    if [ "$auth_mode" != "anonymous" ]; then 
      transport="$transport <keystore name=\"${keystore_dir}/${keystore}\" password=\"$DATAVIRT_TRANSPORT_KEYSTORE_PASSWORD\" type=\"$keystore_type\" key-alias=\"$key_alias\"/><truststore name=\"${keystore_dir}/${keystore}\" password=\"$keystore_pwd\"/>"
    fi

    transport="$transport </ssl></transport>"
        
    # ODBC
    transport="$transport <transport name=\"secure-odbc\" socket-binding=\"secure-teiid-odbc\" protocol=\"pg\"><authentication "
        
    transport="$transport security-domain=\"$odbcsecdomain\"/><ssl mode=\"enabled\" authentication-mode=\"$auth_mode\" ssl-protocol=\"TLSv1.2\" keymanagement-algorithm=\"SunX509\">"


    if [ "$auth_mode" != "anonymous" ]; then
      transport="$transport <keystore name=\"${keystore_dir}/${keystore}\" password=\"$DATAVIRT_TRANSPORT_KEYSTORE_PASSWORD\" type=\"$keystore_type\" key-alias=\"$key_alias\"/><truststore name=\"${keystore_dir}/${keystore}\" password=\"$keystore_pwd\"/>"
    fi

    transport="$transport </ssl></transport>"

    sed -i "s|<!-- ##TEIID_SECURE_TRANSPORT## -->|${transport}|g" ${CONFIG_FILE}
    
    log_info "Secured transports added to configuration"
  fi
}
