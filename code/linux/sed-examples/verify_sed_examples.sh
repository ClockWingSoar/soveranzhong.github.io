#!/bin/bash

# Verification script for sed blog post examples
# This script creates test files and runs sed commands to verify their output matches expectations.

set -e

echo "Starting sed verification..."

# Create test directory
mkdir -p /tmp/sed_verify
cd /tmp/sed_verify

# --- Test Case 1: Hold Space (h, p, n, p, g, p) ---
echo "Test Case 1: Hold Space (h, p, n, p, g, p)"
cat > data2.txt << 'EOF'
Header Line
First Data Line
Second Data Line
End of Data Lines
EOF

EXPECTED_OUTPUT="First Data Line
Second Data Line
First Data Line"

ACTUAL_OUTPUT=$(sed -n '/First/ {
  h ; p ;
  n ; p ;
  g ; p }
' data2.txt)

if [ "$ACTUAL_OUTPUT" = "$EXPECTED_OUTPUT" ]; then
    echo "PASS: Hold Space Test 1"
else
    echo "FAIL: Hold Space Test 1"
    echo "Expected:"
    echo "$EXPECTED_OUTPUT"
    echo "Actual:"
    echo "$ACTUAL_OUTPUT"
    exit 1
fi

# --- Test Case 2: Multi-line N (Merge lines) ---
echo "Test Case 2: Multi-line N (Merge lines)"
cat > data2_N.txt << 'EOF'
Header Line
First Data Line
Second Data Line
End of Data Lines
EOF

EXPECTED_OUTPUT="Header Line
First Data Line Second Data Line
End of Data Lines"

ACTUAL_OUTPUT=$(sed '/First/{ N ; s/\n/ / }' data2_N.txt)

if [ "$ACTUAL_OUTPUT" = "$EXPECTED_OUTPUT" ]; then
    echo "PASS: Multi-line N Test"
else
    echo "FAIL: Multi-line N Test"
    echo "Expected:"
    echo "$EXPECTED_OUTPUT"
    echo "Actual:"
    echo "$ACTUAL_OUTPUT"
    exit 1
fi

# --- Test Case 3: Multi-line D (Delete first line of pattern space) ---
echo "Test Case 3: Multi-line D (Delete first line)"
cat > data4.txt << 'EOF'
On Tuesday, the Linux System
Admin group meeting will be held.
All System Admins should attend.
EOF

EXPECTED_OUTPUT="Admin group meeting will be held.
All System Admins should attend."

ACTUAL_OUTPUT=$(sed 'N ; /System\nAdmin/D' data4.txt)

if [ "$ACTUAL_OUTPUT" = "$EXPECTED_OUTPUT" ]; then
    echo "PASS: Multi-line D Test"
else
    echo "FAIL: Multi-line D Test"
    echo "Expected:"
    echo "$EXPECTED_OUTPUT"
    echo "Actual:"
    echo "$ACTUAL_OUTPUT"
    exit 1
fi

# --- Test Case 4: Multi-line P (Print first line of pattern space) ---
echo "Test Case 4: Multi-line P (Print first line)"
cat > data3.txt << 'EOF'
On Tuesday, the Linux System
Admin group meeting will be held.
All System Admins should attend.
Thank you for your cooperation.
EOF

EXPECTED_OUTPUT="On Tuesday, the Linux System"

ACTUAL_OUTPUT=$(sed -n 'N ; /System\nAdmin/P' data3.txt)

if [ "$ACTUAL_OUTPUT" = "$EXPECTED_OUTPUT" ]; then
    echo "PASS: Multi-line P Test"
else
    echo "FAIL: Multi-line P Test"
    echo "Expected:"
    echo "$EXPECTED_OUTPUT"
    echo "Actual:"
    echo "$ACTUAL_OUTPUT"
    exit 1
fi

echo "All tests passed successfully!"
rm -rf /tmp/sed_verify
