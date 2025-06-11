#!/bin/bash

# Ensure a domain name was provided
if [ -z "$1" ]; then
  echo "Usage: ./buy-domain.sh <domain-name>"
  exit 1
fi

DOMAIN_NAME="$1"

echo "Checking domain: $DOMAIN_NAME"

# Step 1: Check if domain is already registered in this account
EXISTING_DOMAIN=$(aws route53domains list-domains --query "Domains[?DomainName=='$DOMAIN_NAME'] | [0].DomainName" --output text)

if [ "$EXISTING_DOMAIN" == "$DOMAIN_NAME" ]; then
  echo "Domain '$DOMAIN_NAME' is already registered in this account."
  exit 0
fi

# Step 2: Check if domain is available for registration
AVAILABILITY=$(aws route53domains check-domain-availability --domain-name "$DOMAIN_NAME" --query "Availability" --output text)

if [ "$AVAILABILITY" != "AVAILABLE" ]; then
  echo "Domain '$DOMAIN_NAME' is not available. Status: $AVAILABILITY"
  exit 1
fi

# Step 3: Register domain
echo "Domain is available. Attempting to register..."

aws route53domains register-domain \
  --domain-name "$DOMAIN_NAME" \
  --duration-in-years 1 \
  --admin-contact file://contact.json \
  --registrant-contact file://contact.json \
  --tech-contact file://contact.json \
  --auto-renew \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact

echo "Domain registration requested. Check domain status with:"
echo "aws route53domains get-domain-detail --domain-name $DOMAIN_NAME"
