openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ./data/certs/server.key \
  -out ./data/certs/server.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
