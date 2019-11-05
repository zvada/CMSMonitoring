#!/bin/bash
ENV_SETUP_SCRIPT="/cvmfs/sft.cern.ch/lcg/views/LCG_96/x86_64-centos7-gcc8-opt/setup.sh"
HADOOP_ENV_SETUP_SCRIPT="/cvmfs/sft.cern.ch/lcg/etc/hadoop-confext/hadoop-swan-setconf.sh"
HADOOP_CLIENT_JAR="/eos/project/s/swan/public/hadoop-mapreduce-client-core-2.6.0-cdh5.7.6.jar"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Validation:
if ! klist -s
then
    (>&2 echo -e "This application requires a valid kerberos ticket")
    exit 1
fi

if ! { [ -e  "$ENV_SETUP_SCRIPT" ] \
&& [ -e "$HADOOP_ENV_SETUP_SCRIPT" ]; }
then
    (>&2 echo "the specified environment doesn't exists, check the path and try again")
    exit 1
fi

if ! [ -e "$HADOOP_CLIENT_JAR" ]
then
    (>&2 echo "please check the hadoop client jar location, currently set to $HADOOP_CLIENT_JAR")
    exit 1
fi

source "$ENV_SETUP_SCRIPT"
source "$HADOOP_ENV_SETUP_SCRIPT" analytix

#In lxplus, when running with acrontab, we need to set the java home
# to a jvm with avanced encryption enabled. 
# see https://cern.service-now.com/service-portal/view-request.do?n=RQF1380598 

if [ -e "/usr/lib/jvm/java-1.8.0" ]
then
export JAVA_HOME="/usr/lib/jvm/java-1.8.0"
elif ! (java -XX:+PrintFlagsFinal -version 2>/dev/null |grep -E -q 'UseAES\s*=\s*true')
then
    (>&2 echo "This script requires a java version with AES enabled") 
    exit 1
fi
cd "$SCRIPT_DIR" || exit

# Run the script
spark-submit --master yarn --driver-memory 10g --num-executors 48  --executor-memory 6g\
 --conf spark.driver.extraClassPath="$HADOOP_CLIENT_JAR"\
 "$SCRIPT_DIR/../src/python/CMSMonitoring/scrutiny_plot.py" "$@"
