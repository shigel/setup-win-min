# setup-win-min

# 手順

PowerShellを「管理者として実行する」で起動する。

```
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser
$VerbosePreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12
iwr -useb raw.githubusercontent.com/shigel/setup-win-min/main/setup-win.ps1 | iex
```
