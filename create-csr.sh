#!/bin/bash
echo -n "Api KEY: "
read -r APIKEY

IP_CERT=$(curl -s -4 ip.sb)
ZEROSSL_KEY=$APIKEY
GENERATED_DIR=/etc/nginx/ssl
HTTP_DIR=/var/www/html
cd $GENERATED_DIR

# Create CSR and KEY
openssl ecparam -name prime256v1 -out "ecparam.pem"
openssl req -new -SHA256 -newkey ec:ecparam.pem -nodes -keyout $IP_CERT.key -out $IP_CERT.csr -subj "/C=CN/ST=Shanghai/L=Shanghai/CN=$IP_CERT"

# ZeroSSL REST API
curl -s -X POST https://api.zerossl.com/certificates?access_key=$ZEROSSL_KEY --data-urlencode certificate_csr@$IP_CERT.csr -d certificate_domains=$IP_CERT -d certificate_validity_days=90 -o $IP_CERT.resp

echo "Certificate request created"
ID="$(cat $IP_CERT.resp | jq -r '.id')"
URL=$(cat $IP_CERT.resp | jq -r ".validation.other_methods.\"$IP_CERT\".file_validation_url_http")
FILE_NAME=$(basename $URL)
cat ./$IP_CERT.resp | jq -r ".validation.other_methods.\"$IP_CERT\".file_validation_content|join(\"\n\")" > $HTTP_DIR/.well-known/pki-validation/$FILE_NAME

curl -s -X GET http://api.zerossl.com/certificates/${ID}?access_key=$ZEROSSL_KEY -o status.resp
CERT_STATUS=$(cat status.resp | jq -r '.status')

if [ "$CERT_STATUS" == "draft" ];
then
  echo "Certificate $ID not ready"
  curl -s -X POST https://api.zerossl.com/certificates/${ID}/challenges?access_key=$ZEROSSL_KEY -d validation_method=HTTP_CSR_HASH
  echo "wait 10 seconds"
  sleep 10s
fi

curl -s -X GET http://api.zerossl.com/certificates/${ID}?access_key=$ZEROSSL_KEY -o status.resp
echo "Verify certificate status"
CERT_STATUS=$(cat status.resp | jq -r '.status')

if [ "$CERT_STATUS" == "issued" ];
then
  echo "Certificate issued"
else
  echo "Authentication failed"
  exit 1
fi

echo "download certificate"
curl  https://api.zerossl.com/certificates/${ID}/download?access_key=$ZEROSSL_KEY --output certificate.zip
unzip certificate.zip
cat certificate.crt ca_bundle.crt > fullcert.pem
rm -r ./$IP_CERT.resp ./status.resp
rm -r {certificate.zip,ca_bundle.crt,certificate.crt,ecparam.pem}
