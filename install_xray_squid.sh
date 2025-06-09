#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "❌ Укажи домен как аргумент: ./install_xray_squid.sh <domain>"
  exit 1
fi

DOMAIN="$1"
UUID=$(uuidgen)
TAG="user-${UUID:0:6}"
EMAIL="$UUID"
PASS="x"

echo "📦 Обновляем систему и ставим зависимости..."
apt update && apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring apt-transport-https software-properties-common sudo unzip cron socat jq nano squid apache2-utils certbot

echo "⚡ Устанавливаем Xray..."
mkdir -p /usr/local/etc/xray /var/log/xray
chown -R root:root /var/log/xray
chmod -R 755 /var/log/xray
curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash

echo "🔒 Получаем TLS-сертификат для $DOMAIN..."
systemctl stop nginx 2>/dev/null || true
systemctl stop xray 2>/dev/null || true
certbot certonly --standalone --preferred-challenges http --agree-tos -n -m admin@$DOMAIN -d $DOMAIN

echo "🔁 Создаём крон для автообновления сертификатов..."
cat > /etc/cron.daily/renew-cert.sh <<EOF
#!/bin/bash
certbot renew --quiet --deploy-hook "systemctl restart xray"
EOF
chmod +x /etc/cron.daily/renew-cert.sh

echo "🛠 Настраиваем Xray..."
cat > /usr/local/etc/xray/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "email": "$EMAIL"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
            }
          ]
        },
        "wsSettings": {
          "path": "/ws",
          "headers": {
            "Host": "$DOMAIN"
          }
        }
      },
      "tag": "vless-in",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "http",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 8888,
            "users": [
              {
                "user": "$UUID",
                "pass": "$PASS",
                "auth": "basic"
              }
            ]
          }
        ]
      },
      "tag": "$TAG"
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    },
    {
      "protocol": "dns",
      "tag": "dns-out"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "network": "udp",
        "port": 53,
        "outboundTag": "dns-out"
      },
      {
        "type": "field",
        "inboundTag": ["vless-in"],
        "email": "$EMAIL",
        "outboundTag": "$TAG"
      }
    ]
  }
}
EOF

echo "🧱 Настраиваем Squid..."
cat > /etc/squid/squid.conf <<EOF
http_port 127.0.0.1:8888

auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm Proxy
auth_param basic credentialsttl 1 hours
auth_param basic casesensitive on

acl localnet src 127.0.0.1
acl authenticated proxy_auth REQUIRED

http_access allow localnet authenticated
http_access deny all

logformat custom %ts.%03tu %>a %un %rm %ru %>Hs
access_log /var/log/squid/access.log custom
cache_log /var/log/squid/cache.log

via off
forwarded_for delete
EOF

echo "🔐 Создаём юзера для Squid: $UUID:$PASS"
htpasswd -cb /etc/squid/passwd "$UUID" "$PASS"

echo "⚙️ Настраиваем systemd юнит для Xray..."
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
Group=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

PrivateTmp=false
ProtectSystem=false
ReadWritePaths=/var/log/xray

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Перезапускаем службы..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray --now
systemctl restart squid

echo ""
echo "✅ Всё установлено и работает."
echo "🌐 Домен: $DOMAIN"
echo "🆔 UUID: $UUID"
echo "🔑 Пароль: $PASS"
echo "📦 VLESS config:"
echo ""
echo "vless://$UUID@$DOMAIN:443?encryption=none&security=tls&type=ws&host=$DOMAIN&path=%2Fws#$TAG"
