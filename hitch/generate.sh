

openssl req \
  -newkey rsa:2048 \
  -x509 \
  -nodes \
  -keyout *.localhost.reachdigital.io.key \
  -new \
  -out *.localhost.reachdigital.io.crt \
  -subj /CN=*.localhost.reachdigital.io.pem \
  -reqexts SAN \
  -extensions SAN \
  -config <(cat /etc/ssl/openssl.cnf <(printf '[SAN]\nsubjectAltName=DNS:*.localhost.reachdigital.io,IP:127.0.0.1')) \
  -sha256 \
  -days 3650


openssl x509 -noout -fingerprint -text < *.localhost.reachdigital.io.crt > *.localhost.reachdigital.io.info
cat *.localhost.reachdigital.io.crt *.localhost.reachdigital.io.key > *.localhost.reachdigital.io.pem
chmod 400 *.localhost.reachdigital.io.key *.localhost.reachdigital.io.pem
