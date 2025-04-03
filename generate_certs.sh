# generate self-sigend certificate to terminate at the ALB

# Usage: ./generate_certs.sh

# Set the domain name
DOMAIN_NAME="localhost.localhost.com"

# Generate a private key
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $DOMAIN_NAME.key \
    -out $DOMAIN_NAME.crt \
    -subj "/CN=$DOMAIN_NAME" \
    -addext "subjectAltName=DNS:$DOMAIN_NAME"

# Check if the certificate and key were generated successfully
if [ $? -eq 0 ]; then
  echo "Self-signed certificate and private key generated successfully."
  echo "Certificate: certs/$DOMAIN_NAME.crt"
  echo "Private Key: certs/$DOMAIN_NAME.key"
else
  echo "Failed to generate certificate and private key."
  exit 1
fi

# Create a directory for the certificates if it doesn't exist
mkdir -p certs
# Move the generated certificate and key to the certs directory
mv $DOMAIN_NAME.crt certs/
mv $DOMAIN_NAME.key certs/
# Print the paths to the generated files

echo "Certificate and key have been moved to the certs directory."
echo "Certificate: certs/$DOMAIN_NAME.crt"
echo "Private Key: certs/$DOMAIN_NAME.key"
# Print the expiration date of the certificate
echo "Certificate expiration date:"
openssl x509 -in certs/$DOMAIN_NAME.crt -noout -enddate | cut -d= -f2
# Print the fingerprint of the certificate
echo "Certificate fingerprint:"
openssl x509 -in certs/$DOMAIN_NAME.crt -noout -fingerprint -sha256 | cut -d= -f2