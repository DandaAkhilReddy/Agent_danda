#!/bin/bash

# ============================================
# ReplyCopilot Website Deployment - Vercel
# ============================================

echo "🚀 Deploying ReplyCopilot website to Vercel..."

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

# Navigate to website directory
cd "$(dirname "$0")"

echo "📦 Preparing deployment..."

# Deploy to Vercel
echo "🌐 Deploying to Vercel..."
vercel --prod

echo "✅ Deployment complete!"
echo "🌍 Your website should now be live!"
echo ""
echo "Next steps:"
echo "1. Set up custom domain in Vercel dashboard"
echo "2. Update Calendly URL in HTML"
echo "3. Add Google Analytics tracking code"
echo "4. Test all booking flows"
echo ""
echo "📊 View deployment: https://vercel.com/dashboard"
