#!/bin/bash

# ============================================
# ReplyCopilot Website Deployment - Netlify
# ============================================

echo "🚀 Deploying ReplyCopilot website to Netlify..."

# Check if Netlify CLI is installed
if ! command -v netlify &> /dev/null; then
    echo "❌ Netlify CLI not found. Installing..."
    npm install -g netlify-cli
fi

# Navigate to website directory
cd "$(dirname "$0")"

echo "📦 Preparing deployment..."

# Login to Netlify (if needed)
netlify login

# Deploy to Netlify
echo "🌐 Deploying to Netlify..."
netlify deploy --prod --dir=.

echo "✅ Deployment complete!"
echo "🌍 Your website should now be live!"
echo ""
echo "Next steps:"
echo "1. Set up custom domain in Netlify dashboard"
echo "2. Enable HTTPS (automatic)"
echo "3. Update Calendly URL in HTML"
echo "4. Add environment variables if needed"
echo "5. Set up form notifications"
echo ""
echo "📊 View deployment: https://app.netlify.com/"
