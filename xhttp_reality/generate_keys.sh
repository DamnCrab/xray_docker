#!/bin/sh
KEYS=$(/xray x25519)
PRIV=$(echo "$KEYS" | grep "PrivateKey:" | awk '{print $2}')
PUB=$(echo "$KEYS" | grep "Password:" | awk '{print $2}')

echo ""
echo "=================================================="
echo " ✅ 密钥生成成功! (Xray Key Pair Generated)"
echo "=================================================="
echo ""
echo "PRIVATE KEY (For docker-compose.yml / Server Env):"
echo "$PRIV"
echo ""
echo "PUBLIC KEY (For Client Config / PBK):"
echo "$PUB"
echo ""
echo "=================================================="
