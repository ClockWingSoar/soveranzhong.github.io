#!/bin/bash

echo "=== Nginx Alias Fix Test Script ==="
echo

echo "1. Checking Nginx configuration syntax..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Configuration syntax is valid"
    echo
    
    echo "2. Reloading Nginx configuration..."
    sudo systemctl reload nginx
    
    if [ $? -eq 0 ]; then
        echo "✓ Configuration reloaded successfully"
        echo
        
        echo "3. Testing access to main site..."
        curl -I 127.1
        
        echo
        echo "4. Testing access to /app1/..."
        curl -I 127.1/app1/
        
        echo
        echo "5. Testing access to /app1/index.html..."
        curl -I 127.1/app1/index.html
        
        echo
        echo "6. Displaying content from /app1/index.html..."
        curl 127.1/app1/index.html
        
        echo
        echo "=== Test Complete ==="
        echo "If you see 200 OK responses for /app1/ and /app1/index.html, the fix worked!"
    else
        echo "✗ Failed to reload Nginx configuration"
    fi
else
    echo "✗ Configuration syntax error"
    exit 1
fi