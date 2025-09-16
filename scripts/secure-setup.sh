#!/bin/bash

echo "🔒 Securing E-commerce Platform for GitHub"

# Check if .env exists
if [ ! -f .env ]; then
    echo "📋 Creating .env from template..."
    cp .env.example .env
    echo "⚠️  Please update .env with your actual values before deployment"
fi

# Validate environment variables
echo "🔍 Validating environment setup..."
required_vars=("JWT_SECRET" "MONGODB_URI" "REDIS_URL")

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env 2>/dev/null; then
        echo "❌ Missing required variable: $var"
        exit 1
    fi
done

# Update dependencies
echo "📦 Updating vulnerable dependencies..."
cd applications/product-service && pip install --upgrade gunicorn requests
cd ../user-service && npm audit fix --force

echo "✅ Security setup complete!"
echo ""
echo "📋 Before pushing to GitHub:"
echo "1. Update .env with real values"
echo "2. Test all services"
echo "3. Verify no secrets in code"
echo "4. Run: git add . && git commit -m 'Security fixes'"