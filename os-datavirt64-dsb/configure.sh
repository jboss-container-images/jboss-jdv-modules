#!/bin/sh
# Add default Maven settings with Red Hat/JBoss repositories
set -e

SCRIPT_DIR=$(dirname $0)
ADDED_DIR=${SCRIPT_DIR}/added
SOURCES_DIR="/tmp/artifacts"

cp -p ${ADDED_DIR}/standalone-openshift.xml $JBOSS_HOME/standalone/configuration/

cp ${JBOSS_HOME}/dataVirtualization/dataServiceBuilder/vdb-bench-war.war ${JBOSS_HOME}/standalone/deployments/ds-builder.war
cp ${JBOSS_HOME}/dataVirtualization/dataServiceBuilder/vdb-bench-doc.war ${JBOSS_HOME}/standalone/deployments/ds-builder-help.war
cp ${JBOSS_HOME}/dataVirtualization/dataServiceBuilder/komodo-rest.war ${JBOSS_HOME}/standalone/deployments/vdb-builder.war

rm -rf ${JBOSS_HOME}/dataVirtualization

for dir in $JBOSS_HOME/standalone /deployments; do
  chown -R jboss:root $dir
  chmod -R g+rwX $dir
done

DSB_SERVER_OPTS="-Dkomodo.dataDir=/opt/datavirt/dsb/repo"

 # append DSB Mount Point for komodo.dataDir property  to JAVA_OPTS
echo "# Append DSB Mount Point location to JAVA_OPTS" >> $JBOSS_HOME/bin/standalone.conf
echo "JAVA_OPTS=\"\$JAVA_OPTS ${DSB_SERVER_OPTS}\"" >> $JBOSS_HOME/bin/standalone.conf
