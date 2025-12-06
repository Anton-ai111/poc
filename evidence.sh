#!/bin/bash
# evidence_collector.sh

TARGET="contadigital.ifoodpago.com.br"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EVIDENCE_DIR="akamai_waf_evidence_${TIMESTAMP}"

mkdir -p "$EVIDENCE_DIR"

echo "Collecting evidence for Akamai WAF Information Disclosure..."

# 1. Capture full response with headers
curl -v "https://$TARGET/v1/internet-banking/home/header-details" 2>&1 | tee "$EVIDENCE_DIR/full_response.txt"

# 2. Capture just headers
curl -I "https://$TARGET/v1/internet-banking/home/header-details" > "$EVIDENCE_DIR/headers.txt"

# 3. Capture response body
curl -s "https://$TARGET/v1/internet-banking/home/header-details" > "$EVIDENCE_DIR/response_body.html"

# 4. Test multiple endpoints
ENDPOINTS=(
    "/"
    "/v1/internet-banking/home/header-details"
    "/v1/internet-banking/session-refresh"
    "/api/v1/"
    "/admin/"
    "/assets/index-Bg27qdyH.js"
)

echo "Testing multiple endpoints..."
for endpoint in "${ENDPOINTS[@]}"; do
    echo "Testing: $endpoint"
    curl -s -I "https://$TARGET$endpoint" > "$EVIDENCE_DIR/$(echo $endpoint | tr '/' '_')_headers.txt" 2>/dev/null
    curl -s "https://$TARGET$endpoint" > "$EVIDENCE_DIR/$(echo $endpoint | tr '/' '_')_response.txt" 2>/dev/null
done

# 5. Create summary report
cat > "$EVIDENCE_DIR/vulnerability_report.md" << EOF
# Akamai WAF Information Disclosure Report

## Target
- URL: https://$TARGET
- Date: $(date)
- Vulnerability: Information Disclosure

## Evidence Summary

### 1. Akamai WAF Identification
\`\`\`
$(grep -i "server:" "$EVIDENCE_DIR/headers.txt")
\`\`\`

### 2. Reference ID Exposure
\`\`\`
$(grep -o "Reference.*#[^<]*" "$EVIDENCE_DIR/response_body.html")
\`\`\`

### 3. Akamai Error URLs
\`\`\`
$(grep -o "https://errors.edgesuite.net/[^<]*" "$EVIDENCE_DIR/response_body.html")
\`\`\`

### 4. Affected Endpoints
$(for endpoint in "${ENDPOINTS[@]}"; do
    echo "- https://$TARGET$endpoint"
done)

## Impact
1. WAF vendor disclosure (Akamai)
2. Unique tracking IDs exposed
3. Internal error infrastructure revealed
4. Path disclosure in error messages

## Remediation
1. Configure generic error pages in Akamai
2. Remove Server header
3. Disable reference ID display
4. Implement custom error responses
EOF

echo "Evidence collected in: $EVIDENCE_DIR/"
echo "Report generated: $EVIDENCE_DIR/vulnerability_report.md"
