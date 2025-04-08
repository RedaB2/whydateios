#!/bin/sh

echo "🔧 Injecting GoogleService-Info.plist from base64..."
echo "$GOOGLESERVICE_INFO_B64" | base64 --decode > "${CI_WORKSPACE}/GoogleService-Info.plist"
echo "✅ Injection complete."
