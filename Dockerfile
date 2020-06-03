FROM vault:1.4.1

RUN update-ca-certificates
COPY vault/config.hcl /vault/config