TOP_DIR=$(cd $(dirname "$0") && pwd)
## echo $TOP_DIR
echo Ready to patch
NOVA_CONF="/etc/nova/nova.conf"
echo Patching $NOVA_CONF
if [ ! -e "${NOVA_CONF}.back" ]
then
  cp ${NOVA_CONF} ${NOVA_CONF}.back
else
  cp ${NOVA_CONF}.back ${NOVA_CONF}
fi
awk -f ${TOP_DIR}/patch_nova_conf.awk ${NOVA_CONF} > ${NOVA_CONF}.new
cp ${NOVA_CONF}.new ${NOVA_CONF}
rm ${NOVA_CONF}.new

NOVA_API_PASTE="/etc/nova/api-paste.ini"
echo Patching $NOVA_API_PASTE
if [ ! -e "${NOVA_API_PASTE}.back" ]
then
  cp ${NOVA_API_PASTE} ${NOVA_API_PASTE}.back
else
  cp ${NOVA_API_PASTE}.back ${NOVA_API_PASTE}
fi
awk -f ${TOP_DIR}/patch_nova_api_ini.awk ${NOVA_API_PASTE} > ${NOVA_API_PASTE}.new
cp ${NOVA_API_PASTE}.new ${NOVA_API_PASTE}
rm ${NOVA_API_PASTE}.new

echo Juno pycadf/audit/api.py has a bug and needs to be patched.
CADF_API=`find /usr -type f -path "*/pycadf/audit/api.py"`
if [ -z "$CADF_API" ]
then
   echo Looks that pycadf was not installed. This is a required components, you need to install it.
   exit 1
fi
echo Patching $CADF_API

if [ ! -e "${CADF_API}.back" ]
then
  cp ${CADF_API} ${CADF_API}.back
else
  cp ${CADF_API}.back ${CADF_API}
fi
cp ${TOP_DIR}/pycadf/audit/api.py ${CADF_API}

echo Place cadf mapping file in the right place
cp ${TOP_DIR}/pycadf/nova_api_audit_map.conf /etc/nova/api_audit_map.conf
echo Finished!!!
