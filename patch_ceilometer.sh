if [ -z "$1" ]
then
  echo Usage: $0 QRadar-Endpoint
  echo For example $0 http://qradar_host:port/path
  exit 1
fi
TOP_DIR=$(cd $(dirname "$0") && pwd)
ENDPOINT=$1
echo Ready to patch
CEILOMETER_FILE=`find /usr/ -type f -path "*/ceilometer/collector.py"`
echo $CEILOMETER_FILE
CEILOMETER_DIR=`dirname $CEILOMETER_FILE`
echo ${INSTALLED_DIR}
echo Ready to patch
cp -r ${TOP_DIR}/ceilometer/* ${CEILOMETER_DIR}
echo All new files are now in directory ${CEILOMETER_DIR}

CEILOMETER_BIN_FILE=`which ceilometer-collector`
echo $CEILOMETER_BIN_FILE
BIN_DIR=`dirname $CEILOMETER_BIN_FILE`

cp ${TOP_DIR}/ceilometer-consumer ${BIN_DIR}
awk -v ep=${ENDPOINT} -f ${TOP_DIR}/patch_ceilometer_conf.awk /etc/ceilometer/ceilometer.conf > /etc/ceilometer/consumer.conf
EGG_FILE=`find /usr -type f -path "*/ceilometer-201*.egg-info/entry_points.txt"`
echo Saving $EGG_FILE
if [ ! -e "${EGG_FILE}.back" ]
then
  cp ${EGG_FILE} ${EGG_FILE}.back
else
  cp ${EGG_FILE}.back ${EGG_FILE}
fi
echo Patching ${EGG_FILE}
awk -f ${TOP_DIR}/patch_egg_info.awk ${EGG_FILE} > ${EGG_FILE}.new
cp ${EGG_FILE}.new ${EGG_FILE}
rm ${EGG_FILE}.new
echo Patched file ${EGG_FILE}
echo Finished!!!
