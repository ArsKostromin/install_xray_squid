# install_xray_squid


````markdown
# 🚀 Автоматическая установка Xray + Squid с TLS

Этот скрипт устанавливает Xray с VLESS+WS+TLS и Squid-прокси с авторизацией через `htpasswd`. Всё в автоматическом режиме: от получения сертификата до запуска systemd-сервисов.

## 🧾 Что ставим

- ✅ Xray (VLESS, WS, TLS)
- ✅ Squid на `127.0.0.1:8888` с логином/паролем
- ✅ Let's Encrypt TLS сертификат
- ✅ Cron для автообновления сертификата
- ✅ Логи Xray и Squid

---

## 📦 Зависимости

Скрипт сам всё поставит:

```bash
curl gnupg2 ca-certificates lsb-release debian-archive-keyring apt-transport-https software-properties-common sudo unzip cron socat jq nano squid apache2-utils certbot
````

---

## ⚙️ Как использовать

1. **Убедись**, что:

   * У тебя есть **домен**, направленный на сервер (A-запись работает)
   * На сервере **ничего не занимает порт 443**

2. **Склонируй и запусти скрипт**:

```bash
git clone https://github.com/твой-гит/xray-squid-auto.git
cd xray-squid-auto
chmod +x install_xray_squid.sh
./install_xray_squid.sh example.com
```

Замени `example.com` на свой домен.

3. **После установки** ты увидишь VLESS-конфиг:

```
vless://<UUID>@<domain>:443?encryption=none&security=tls&type=ws&host=<domain>&path=%2Fws#user-XXXXXX
```

---

## 🛠 Где что лежит

| Что                     | Путь                                    |
| ----------------------- | --------------------------------------- |
| Xray конфиг             | `/usr/local/etc/xray/config.json`       |
| Логи Xray               | `/var/log/xray/access.log`, `error.log` |
| Squid конфиг            | `/etc/squid/squid.conf`                 |
| Squid пароли            | `/etc/squid/passwd`                     |
| TLS сертификат          | `/etc/letsencrypt/live/<domain>/`       |
| Cron автообновления TLS | `/etc/cron.daily/renew-cert.sh`         |

---

## 🧯 Возможные проблемы

| Проблема                               | Решение                                             |
| -------------------------------------- | --------------------------------------------------- |
| `certbot` не может получить сертификат | Убедись, что DNS работает и порт 80/443 не занят    |
| Xray не стартует                       | Проверяй `journalctl -u xray -xe`                   |
| Squid ругается                         | Смотри `journalctl -u squid -xe` и проверь `passwd` |
| Сертификат не продлевается             | Запусти вручную: `certbot renew`                    |

---

## 🔐 Безопасность

* Squid слушает только `127.0.0.1`
* Все подключения идут через TLS
* UUID + пароль шифруются в WebSocket

---

## 🤘 Автор

Скрипт сделан с душой и ненавистью к ручной настройке.

---


