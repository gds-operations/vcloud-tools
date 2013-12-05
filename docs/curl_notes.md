Talking to vCloud Director via curl
====

* See http://blogs.vmware.com/vsphere/2012/03/exploring-the-vcloud-rest-api-part-1.html
* also utils/vcloud-curl

Get a login session:

    curl -i -k \
      -H 'Accept:application/*+xml;version=1.5' \
      -u "${USER}@${ORG}:${PASS}" \
      -X POST \
      "https://${HOST}/api/sessions"

Session is i t
 
then make requests with this session:

    curl -i -k \
      -H 'Accept:application/*+xml;version=1.5' \
      -H "x-vcloud-authorization: btabjudq0cz09KCaZT0QJoJsy1SHaCyJd5hnjGPw7fw=" \
      -X GET \
      "https://${HOST}/api/Vm/vm-1"


and log out:

    curl -i -k \
      -H 'Accept:application/*+xml;version=1.5' \
      -H "x-vcloud-authorization: btabjudq0cz09KCaZT0QJoJsy1SHaCyJd5hnjGPw7fw=" \
      -X DELETE \
      https://10.20.181.101/api/session

