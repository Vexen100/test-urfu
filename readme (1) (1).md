Приветствую в директории установки промтэила 3.6.3 для виндовс через службы и nssm

Кратко, нам надо создать директории, можно в ручную или через cmd, как вам удобнее

✅ 1. Директории созданы:

C:\Promtail\

C:\Promtail\logs\

C:\Promtail\positions\

C:\Tools\NSSM\

✅ 2. Файлы скачаны и распакованы:

NSSM → C:\Tools\NSSM\win64\nssm.exe

Promtail → C:\Promtail\promtail-windows-amd64.exe

✅ 3. Конфиг создан:

C:\Promtail\promtail-config.yml

✅ 4. Папки с логами существуют:

C:\_tmp\logs\pushdemca\ (может быть пустой)

C:\inetpub\logs\LogFiles\W3SVC1\ (IIS должен создать)

Есть одна проблема с nssm, их официальный сайт падает или не доступен в некоторых регионах(странах) еще у некоторых провайдеров работает стабильнее, если не получается скачать с 1 раза, подождите мин 10

"https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip"

"https://github.com/grafana/loki/releases/download/v3.6.3/promtail-windows-amd64.exe.zip"

Дальше установка через cmd, не забудьте зайти через администратора

REM Переходим в папку с NSSM

cd C:\Tools\NSSM\win64

REM Устанавливаем службу Promtail

nssm install Promtail C:\Promtail\promtail-windows-amd64.exe

REM Настраиваем параметры

nssm set Promtail AppDirectory C:\Promtail

nssm set Promtail AppParameters "-config.file=C:\Promtail\promtail-config.yml"

nssm set Promtail AppStdout C:\Promtail\logs\promtail.log

nssm set Promtail AppStderr C:\Promtail\logs\promtail-error.log

nssm set Promtail Start SERVICE_AUTO_START

nssm set Promtail Description "Promtail 3.6.3 - Log collector for Loki"

REM Автоперезапуск при сбое

nssm set Promtail AppExit Default Restart

nssm set Promtail AppRestartDelay 5000

nssm set Promtail AppThrottle 15000

REM Запускаем службу

nssm start Promtail

последняя команда может не сработать через кмд, там разные ошибки, можно через графику запустить или через сервис служб

примерный конфиг я залью в promtail-config.yml для винды