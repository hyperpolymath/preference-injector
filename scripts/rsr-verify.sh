#!/bin/bash
# Quick RSR compliance verification (bash version)

echo "🔍 RSR Compliance Verification"
echo "================================"
echo ""

total_bronze=0
earned_bronze=0
total_silver=0
earned_silver=0
total_gold=0
earned_gold=0

# 1. Type Safety
echo "1. Type Safety"
if [ -n "$(git ls-files 'src/**/*.affine' 2>/dev/null)" ]; then
  echo "  ✅ Bronze: 80/80 points"
  earned_bronze=$((earned_bronze + 80))
else
  echo "  ❌ Bronze: 0/80 points"
fi
total_bronze=$((total_bronze + 80))

if [ -f "Justfile" ] || [ -f "justfile" ]; then
  echo "  ✅ Silver: 20/20 points"
  earned_silver=$((earned_silver + 20))
else
  echo "  ⚠️  Silver: 0/20 points"
fi
total_silver=$((total_silver + 20))

# 2. Memory Safety
echo ""
echo "2. Memory Safety"
if [ -n "$(git ls-files 'src/**/*.affine' 2>/dev/null)" ]; then
  echo "  ✅ Bronze: 40/40 points"
  earned_bronze=$((earned_bronze + 40))
else
  echo "  ❌ Bronze: 0/40 points"
fi
total_bronze=$((total_bronze + 40))
total_gold=$((total_gold + 60))
echo "  ⚠️  Gold: 0/60 points (Rust core)"

# 3. Offline-First
echo ""
echo "3. Offline-First"
if [ -n "$(git ls-files 'src/**/providers/*.affine' 2>/dev/null)" ]; then
  echo "  ✅ Bronze: 50/50 points"
  earned_bronze=$((earned_bronze + 50))
else
  echo "  ❌ Bronze: 0/50 points"
fi
total_bronze=$((total_bronze + 50))

# Check for CRDT implementation
if [ -n "$(git ls-files 'src/**/crdt/LWWMap.affine' 2>/dev/null)" ] && [ -n "$(git ls-files 'src/**/crdt/Merge.affine' 2>/dev/null)" ]; then
  echo "  ✅ Silver: 30/30 points"
  earned_silver=$((earned_silver + 30))
else
  echo "  ⚠️  Silver: 0/30 points (CRDT sync)"
fi
total_silver=$((total_silver + 30))

total_gold=$((total_gold + 20))
echo "  ⚠️  Gold: 0/20 points (Full offline)"

# 4. Documentation
echo ""
echo "4. Documentation"
docs_missing=0
for doc in README SECURITY CODE_OF_CONDUCT MAINTAINERS CONTRIBUTING CHANGELOG; do
  [ ! -f "$doc.md" ] && [ ! -f "$doc.adoc" ] && docs_missing=1
done
[ ! -f "LICENSE" ] && docs_missing=1
if [ $docs_missing -eq 0 ]; then
  echo "  ✅ Bronze: 60/60 points"
  earned_bronze=$((earned_bronze + 60))
else
  echo "  ❌ Bronze: 0/60 points"
fi
total_bronze=$((total_bronze + 60))

if [ -f "docs/API.md" ] || [ -f "docs/API.adoc" ]; then
  echo "  ✅ Silver: 40/40 points"
  earned_silver=$((earned_silver + 40))
else
  echo "  ⚠️  Silver: 0/40 points (API docs)"
fi
total_silver=$((total_silver + 40))

# 5. Build System
echo ""
echo "5. Build System"
if [ -f "Justfile" ] || [ -f "justfile" ]; then
  echo "  ✅ Bronze: 40/40 points"
  earned_bronze=$((earned_bronze + 40))
else
  echo "  ❌ Bronze: 0/40 points"
fi
total_bronze=$((total_bronze + 40))

if [ -f "guix.scm" ]; then
  echo "  ✅ Silver: 30/30 points"
  earned_silver=$((earned_silver + 30))
else
  echo "  ⚠️  Silver: 0/30 points"
fi
total_silver=$((total_silver + 30))
total_gold=$((total_gold + 30))
echo "  ⚠️  Gold: 0/30 points (Multi-platform builds)"

# 6. Testing
echo ""
echo "6. Testing"
if [ -d "tests/" ]; then
  echo "  ✅ Bronze: 50/50 points"
  earned_bronze=$((earned_bronze + 50))
else
  echo "  ❌ Bronze: 0/50 points"
fi
total_bronze=$((total_bronze + 50))
total_silver=$((total_silver + 30))
total_gold=$((total_gold + 20))
echo "  ⚠️  Silver: 0/30 points (100% pass rate)"
echo "  ⚠️  Gold: 0/20 points (Property-based testing)"

# 7. Security
echo ""
echo "7. Security"
if [ -f "SECURITY.md" ] || [ -f "SECURITY.adoc" ]; then
  echo "  ✅ Bronze: 30/30 points"
  earned_bronze=$((earned_bronze + 30))
else
  echo "  ❌ Bronze: 0/30 points"
fi
total_bronze=$((total_bronze + 30))

# Check for post-quantum crypto implementation
if [ -n "$(git ls-files 'src/**/crypto/Signatures.affine' 2>/dev/null)" ] && [ -n "$(git ls-files 'src/**/crypto/KeyExchange.affine' 2>/dev/null)" ] && [ -n "$(git ls-files 'src/**/crypto/Hashing.affine' 2>/dev/null)" ]; then
  echo "  ✅ Silver: 40/40 points"
  earned_silver=$((earned_silver + 40))
else
  echo "  ⚠️  Silver: 0/40 points (Post-quantum crypto)"
fi
total_silver=$((total_silver + 40))

total_gold=$((total_gold + 30))
echo "  ⚠️  Gold: 0/30 points (Formal verification)"

# 8. .well-known/
echo ""
echo "8. .well-known/"
wellknown_missing=0
for file in .well-known/security.txt .well-known/ai.txt .well-known/humans.txt; do
  [ ! -f "$file" ] && wellknown_missing=1
done
if [ $wellknown_missing -eq 0 ]; then
  echo "  ✅ Bronze: 100/100 points"
  earned_bronze=$((earned_bronze + 100))
else
  echo "  ❌ Bronze: 0/100 points"
fi
total_bronze=$((total_bronze + 100))

# 9. TPCF
echo ""
echo "9. TPCF"
if [ -f "MAINTAINERS.adoc" ] && grep -q "Perimeter" MAINTAINERS.adoc; then
  echo "  ✅ Bronze: 50/50 points"
  earned_bronze=$((earned_bronze + 50))
else
  echo "  ❌ Bronze: 0/50 points"
fi
total_bronze=$((total_bronze + 50))
total_silver=$((total_silver + 50))
echo "  ⚠️  Silver: 0/50 points (Automated promotion)"

# 10. Licensing
echo ""
echo "10. Licensing"
if [ -f "LICENSE" ]; then
  echo "  ✅ Bronze: 100/100 points"
  earned_bronze=$((earned_bronze + 100))
else
  echo "  ❌ Bronze: 0/100 points"
fi
total_bronze=$((total_bronze + 100))
# Silver is 0 points for PALIMPSEST
total_silver=$((total_silver + 0))

# 11. Distribution
echo ""
echo "11. Distribution"
platform_missing=0
for file in .gitlab-ci.yml .github/workflows/ci-extended.yml bitbucket-pipelines.yml; do
  [ ! -f "$file" ] && platform_missing=1
done
if [ $platform_missing -eq 0 ]; then
  echo "  ✅ Bronze: 50/50 points"
  earned_bronze=$((earned_bronze + 50))
else
  echo "  ❌ Bronze: 0/50 points"
fi
total_bronze=$((total_bronze + 50))

if [ -f ".vscode/preference-injector.code-snippets" ]; then
  echo "  ✅ Silver: 50/50 points"
  earned_silver=$((earned_silver + 50))
else
  echo "  ⚠️  Silver: 0/50 points (Editor snippets)"
fi
total_silver=$((total_silver + 50))

# Calculate totals
echo ""
echo "================================"
total_points=$((total_bronze + total_silver + total_gold))
earned_points=$((earned_bronze + earned_silver + earned_gold))

echo ""
echo "📊 Score Breakdown:"
echo "   Bronze: $earned_bronze/$total_bronze points"
echo "   Silver: $earned_silver/$total_silver points"
echo "   Gold: $earned_gold/$total_gold points"
echo ""
echo "📊 Total Score: $earned_points/$total_points points"

# Calculate percentage
percentage=$((earned_points * 100 / total_points))
echo "   Percentage: $percentage%"
echo ""

# Determine tier
if [ $percentage -ge 95 ]; then
  echo "💎 Compliance Tier: Rhodium"
elif [ $percentage -ge 85 ]; then
  echo "🥇 Compliance Tier: Gold"
elif [ $percentage -ge 75 ]; then
  echo "🥈 Compliance Tier: Silver"
elif [ $percentage -ge 70 ]; then
  echo "🥉 Compliance Tier: Bronze"
else
  echo "❌ Not yet compliant (need 70% for Bronze)"
  echo ""
  echo "Points needed for Bronze: $((total_points * 70 / 100 - earned_points))"
fi
echo ""
