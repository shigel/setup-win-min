# setup-win-min

```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser
$VerbosePreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12
iwr -useb raw.githubusercontent.com/shigel/setup-win-min/main/setup-win.ps1 | iex
```
