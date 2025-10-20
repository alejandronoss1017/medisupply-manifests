#!/bin/bash

# Medicine Endpoints Testing Script
# Make sure the suppliers-ms service is running on port 3001

BASE_URL="http://localhost:3001"

echo "=== Testing Medicine Endpoints ==="
echo ""

# Test 1: Health check
echo "1. Testing health endpoint..."
curl -s -X GET "$BASE_URL/health" | jq '.'
echo ""

# Test 2: Create medicine - Success case
echo "2. Testing POST /medicines (success case)..."
RESPONSE=$(curl -s -X POST "$BASE_URL/medicines" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Aspirin",
    "description": "Pain reliever and anti-inflammatory medication",
    "price": 15.99,
    "category": "Analgesic",
    "supplierId": {"id": "supplier-123", "name": "PharmaCorp"}
  }')
echo "$RESPONSE" | jq '.'

# Extract medicine ID for update test
MEDICINE_ID=$(echo "$RESPONSE" | jq -r '.data.medicine.id // "test-id"')
echo "Created medicine ID: $MEDICINE_ID"
echo ""

# Test 3: Create medicine - Error case (missing name)
echo "3. Testing POST /medicines (error case - missing name)..."
curl -s -X POST "$BASE_URL/medicines" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Medicine without name",
    "price": 10.00
  }' | jq '.'
echo ""

# Test 4: Create medicine - Error case (empty name)
echo "4. Testing POST /medicines (error case - empty name)..."
curl -s -X POST "$BASE_URL/medicines" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "",
    "description": "Medicine with empty name"
  }' | jq '.'
echo ""

# Test 5: Update medicine - Success case
echo "5. Testing PUT /medicines/:id (success case)..."
curl -s -X PUT "$BASE_URL/medicines/$MEDICINE_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"$MEDICINE_ID\",
    \"name\": \"Aspirin Extra Strength\",
    \"description\": \"Enhanced pain reliever and anti-inflammatory medication\",
    \"price\": 19.99,
    \"category\": \"Analgesic\",
    \"supplierId\": {\"id\": \"supplier-123\", \"name\": \"PharmaCorp\"}
  }" | jq '.'
echo ""

# Test 6: Update medicine - Error case (missing name)
echo "6. Testing PUT /medicines/:id (error case - missing name)..."
curl -s -X PUT "$BASE_URL/medicines/$MEDICINE_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"$MEDICINE_ID\",
    \"description\": \"Updated medicine without name\",
    \"price\": 25.00
  }" | jq '.'
echo ""

# Test 7: Minimal medicine creation
echo "7. Testing POST /medicines (minimal data)..."
curl -s -X POST "$BASE_URL/medicines" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Basic Medicine"
  }' | jq '.'
echo ""

echo "=== Testing Complete ==="
