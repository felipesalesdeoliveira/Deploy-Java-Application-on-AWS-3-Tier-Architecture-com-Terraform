#!/bin/bash
set -euxo pipefail

yum update -y
yum install -y java-17-amazon-corretto-headless tomcat jq awscli

cat > /etc/tomcat/tomcat.conf <<TOMCATENV
JAVA_OPTS="-Dspring.datasource.url=jdbc:mysql://${db_endpoint}:${db_port}/${db_name} -Dspring.datasource.username=${db_username} -Dspring.datasource.password=${db_password}"
TOMCATENV

chown root:tomcat /etc/tomcat/tomcat.conf
chmod 640 /etc/tomcat/tomcat.conf

if [ -n "${java_artifact_url}" ]; then
  curl -fsSL "${java_artifact_url}" -o /var/lib/tomcat/webapps/ROOT.war
fi

systemctl enable tomcat
systemctl restart tomcat
