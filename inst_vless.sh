#!/bin/bash

set -e

echo "========================================="
echo " VLESS + Reality Installer"
echo "========================================="
echo

read -p "Введите домен для маскировки (например tolko_ne_apple.com): " MASK_DOMAIN

if [ -z "$MASK_DOMAIN" ]; then
echo "Ошибка: домен не указан."
exit 1
fi

echo
echo "Установка Xray..."

bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

echo
echo "Генерация Reality ключей..."

KEYS=$(xray x25519)

PRIVATE_KEY=$(echo "$KEYS" | grep "^PrivateKey:" | awk '{print $2}')
PUBLIC_KEY=$(echo "$KEYS" | grep "^Password (PublicKey):" | awk '{print $3}')

if [ -z "$PRIVATE_KEY" ]; then
echo "Ошибка получения PrivateKey."
exit 1
fi

if [ -z "$PUBLIC_KEY" ]; then
echo "Ошибка получения PublicKey."
exit 1
fi

echo "Reality ключи успешно созданы."

echo
echo "Создание пользователей..."

UUID1=$(cat /proc/sys/kernel/random/uuid)
UUID2=$(cat /proc/sys/kernel/random/uuid)
UUID3=$(cat /proc/sys/kernel/random/uuid)
UUID4=$(cat /proc/sys/kernel/random/uuid)
UUID5=$(cat /proc/sys/kernel/random/uuid)

SID1=$(openssl rand -hex 8)
SID2=$(openssl rand -hex 8)
SID3=$(openssl rand -hex 8)
SID4=$(openssl rand -hex 8)
SID5=$(openssl rand -hex 8)

SERVER_IP=$(curl -4 -s https://api.ipify.org)

mkdir -p /usr/local/etc/xray

cat > /usr/local/etc/xray/config.json <<EOF
{
"inbounds": [
{
"port": 443,
"protocol": "vless",
"settings": {
"clients": [
{
"id": "$UUID1",
"flow": "xtls-rprx-vision"
},
{
"id": "$UUID2",
"flow": "xtls-rprx-vision"
},
{
"id": "$UUID3",
"flow": "xtls-rprx-vision"
},
{
"id": "$UUID4",
"flow": "xtls-rprx-vision"
},
{
"id": "$UUID5",
"flow": "xtls-rprx-vision"
}
],
"decryption": "none"
},
"streamSettings": {
"network": "tcp",
"security": "reality",
"realitySettings": {
"show": false,
"dest": "${MASK_DOMAIN}:443",
"xver": 0,
"serverNames": [
"${MASK_DOMAIN}"
],
"privateKey": "${PRIVATE_KEY}",
"shortIds": [
"${SID1}",
"${SID2}",
"${SID3}",
"${SID4}",
"${SID5}"
]
}
}
}
],
"outbounds": [
{
"protocol": "freedom"
}
]
}
EOF

echo
echo "Проверка конфигурации..."

if ! xray run -test -config /usr/local/etc/xray/config.json; then
echo
echo "Ошибка в конфигурации."
exit 1
fi

systemctl enable xray
systemctl restart xray

REPORT=/root/reality-users.txt

{
echo "========================================="
echo "VLESS + Reality"
echo "========================================="
echo
echo "Дата установки: $(date)"
echo "IP сервера: ${SERVER_IP}"
echo "Домен маскировки: ${MASK_DOMAIN}"
echo
echo "Reality Public Key:"
echo "${PUBLIC_KEY}"
echo
echo "Reality Private Key:"
echo "${PRIVATE_KEY}"
echo
} > "$REPORT"

for N in 1 2 3 4 5
do
    UUID_VAR="UUID${N}"
    SID_VAR="SID${N}"

    UUID_VALUE=${!UUID_VAR}
    SID_VALUE=${!SID_VAR}

    {
        echo "========================================="
        echo "USER ${N}"
        echo "========================================="
        echo
        echo "UUID: ${UUID_VALUE}"
        echo "ShortID: ${SID_VALUE}"
        echo
        echo "vless://${UUID_VALUE}@${SERVER_IP}:443?encryption=none&security=reality&type=tcp&sni=${MASK_DOMAIN}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SID_VALUE}&flow=xtls-rprx-vision#user${N}"
        echo
    } >> "$REPORT"
done

echo
echo "========================================="
echo "Установка завершена"
echo "========================================="
echo
echo "Все данные сохранены:"
echo
echo "nano /root/reality-users.txt"
echo
echo "Рекомендуется заменить пользователя сервиса:"
echo
echo "useradd -r -s /usr/sbin/nologin xray"
echo "nano /etc/systemd/system/xray.service"
echo
echo "Найдите:"
echo
echo "User=nobody"
echo
echo "Замените на:"
echo
echo "User=xray"
echo
echo "После сохранения выполните:"
echo
echo "systemctl daemon-reexec"
echo "systemctl daemon-reload"
echo "systemctl restart xray"
echo
echo "========================================="
