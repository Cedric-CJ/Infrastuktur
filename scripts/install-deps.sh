#!/usr/bin/env bash
# Install Lambda dependencies for all functions

set -e

echo "📦 Installing Lambda dependencies..."

cd lambdas/auth_signup && npm install --omit=dev
cd ../auth_login && npm install --omit=dev
cd ../comments_write && npm install --omit=dev
cd ../reactions_write && npm install --omit=dev

echo "✅ All Lambda dependencies installed"
