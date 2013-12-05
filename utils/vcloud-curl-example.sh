#!/bin/sh

# This is an illustrative (functional) example of how to use just curl 
# to talk to the vCloud API. 
#
# The rest of the tools in vcloud-tools use Fog and hence have a unified 
# credential/session handling system - and should as a result be used instead
# of this example.
#

usage() {
  echo "vcloud-curl: simple curl wrapper to allow GET requests to vcloud API"
  echo
  echo "Usage:"
  echo "  vcloud-curl-example.sh {request}"
  echo 
  echo "where {request} is the resource required after the /api end point"
  echo "eg: vcloud-curl-example.sh vApp/{vm-id}/virtualHardwareSection/cpu"
  echo 
  echo "You must set in environment:"
  echo "  VCLOUD_HOST"
  echo "  VCLOUD_ORG"
  echo "  VCLOUD_USER"
  echo "  VCLOUD_PASS"
  exit 1
}

[ -z "$VCLOUD_HOST" ] && usage
[ -z "$VCLOUD_ORG" ]  && usage
[ -z "$VCLOUD_USER" ] && usage
[ -z "$VCLOUD_PASS" ] && usage

CURL_OPTS=${CURL_OPTS-'--silent'} 
MAIN_QUERY_CURL_OPTS=${MAIN_QUERY_CURL_OPTS-''} 

api_version=${VCLOUD_API_VERSION-'5.1'} 

MAIN_QUERY_CONTENT_TYPE=${MAIN_QUERY_CONTENT_TYPE-"application/*+xml;version=${api_version}"}

SESSION_KEY=`curl --include $CURL_OPTS \
   -H "Accept:application/*+xml;version=${api_version}" \
   -u "${VCLOUD_USER}@${VCLOUD_ORG}:${VCLOUD_PASS}" \
   -X POST \
   "https://${VCLOUD_HOST}/api/sessions" \
   | grep '^x-vcloud-authorization:' \
   | tr -d '\r' \
   | awk '{print $2}'
   `

if [ -z "${SESSION_KEY}" ]; then
  echo "Failed to get vCloud session. Bailing"
  exit 2
fi

curl $CURL_OPTS $MAIN_QUERY_CURL_OPTS \
   -H "Accept:${MAIN_QUERY_CONTENT_TYPE}" \
   -H "x-vcloud-authorization: ${SESSION_KEY}" \
   "https://${VCLOUD_HOST}/api/$1"

# Log out
curl $CURL_OPTS \
   -H "Accept:application/*+xml;version=${api_version}" \
   -H "x-vcloud-authorization: ${SESSION_KEY}" \
   -X DELETE \
   "https://${VCLOUD_HOST}/api/session"

