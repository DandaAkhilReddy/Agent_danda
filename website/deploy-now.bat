@echo off
echo ========================================
echo   ReplyCopilot Website Deployment
echo ========================================
echo.

echo Step 1: Login to Vercel
echo This will open your browser...
call vercel login
echo.

echo Step 2: Deploy to Production
echo.
call vercel --prod
echo.

echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Your website is now live!
echo Copy the URL from above.
echo.
pause
