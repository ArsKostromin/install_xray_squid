# 🚀 Автоматическая установка Xray + Squid с TLS

Скрипт ставит готовый прокси-сервер с Xray (VLESS+WS+TLS) и Squid. Всё на автомате: от получения TLS-серта до запуска systemd-сервисов и прокидывания трафика.

## 🧾 Что устанавливается

- ✅ **Xray** с VLESS over WebSocket + TLS
- ✅ **Squid** на `127.0.0.1:8888` с HTTP Basic Auth (`htpasswd`)
- ✅ **Let's Encrypt TLS** сертификат через `certbot`
- ✅ **Cron** для автообновления сертификата
- ✅ **Логи** Xray и Squid

---

## 📦 Зависимости

Скрипт сам установит всё нужное через `apt`, вручную ставить ничего не нужно.

---

## ⚙️ Как использовать

1. **Убедись, что:**

   - У тебя есть **домен**, указывающий на IP сервера (A-запись работает)
   - Порты **80 и 443 свободны** (иначе `certbot` не получит сертификат)

2. **Склонируй репозиторий и запусти скрипт:**

   ```bash
   git clone https://github.com/ArsKostromin/install_xray_squid.git
   cd xray-squid-auto
   chmod +x install_xray_squid.sh
   ./install_xray_squid.sh example.com
   ```

   Замени `example.com` на свой домен.

3. **После установки** ты увидишь конфиг-ссылку:

   ```
   vless://<UUID>@<domain>:443?encryption=none&security=tls&type=ws&host=<domain>&path=%2Fws#user-XXXXXX
   ```

---

## 🛠 Где что лежит

| Что                     | Путь                                      |
|--------------------------|-------------------------------------------|
| Конфиг Xray              | `/usr/local/etc/xray/config.json`         |
| Логи Xray                | `/var/log/xray/access.log`, `error.log`   |
| Конфиг Squid             | `/etc/squid/squid.conf`                   |
| Пароли для Squid         | `/etc/squid/passwd`                       |
| TLS-сертификаты          | `/etc/letsencrypt/live/<domain>/`         |
| Cron для автообновления  | `/etc/cron.daily/renew-cert.sh`           |

---

## 🧯 Возможные проблемы

| Проблема                                | Решение                                                |
|-----------------------------------------|---------------------------------------------------------|
| `certbot` не получает сертификат        | Проверь, что порт 80 открыт и DNS настроен             |
| Xray не стартует                        | `journalctl -u xray -xe` или `systemctl status xray`   |
| Squid ругается                          | `journalctl -u squid -xe` и проверь файл `passwd`      |
| TLS-сертификат не обновляется           | Запусти вручную: `certbot renew --dry-run`             |

---

## 🔐 Безопасность

- Squid слушает **только localhost**
- Весь внешний трафик идёт через **TLS (443)**
- Авторизация по **UUID + паролю**
- Конфиги не раскрываются публично

---

## 🤘 Автор

Скрипт сделан с ленью, болью и ненавистью к ручной настройке. Работает с первого раза. Или со второго.

---

## 🐉 Пример ссылки VLESS

```
vless://UUID@domain.com:443?encryption=none&security=tls&type=ws&host=domain.com&path=%2Fws#user-abcdef
```

