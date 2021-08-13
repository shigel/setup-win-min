# setup-win-min

## 概要

PowerShellから自動で環境構築できるよう、最低限の設定を行う。

### 設定する内容

- PowerShell初期設定
- PackageManagement初期設定
- Scoopインストール、初期設定
- sshインストール、初期設定
  - ※最後に公開鍵を表示します
- slackへの通知
  - 下記オプションを設定することでslackへの通知が可能です
    - `$slackWebhookUrl`: 通知先slackチャンネルのWebHookURLを設定する(任意)
    - `$slackMentionSubteamId`: メンションするグループのIDを指定(任意)
      - ※設定しない場合は`@here`宛に通知する
- [Snipe-IT](https://snipeitapp.com/)への資産登録
  - 下記オプションを設定することでSnipe-ITへの資産登録が可能です
    - `$assetTag`: 登録する資産タグを指定 (任意、登録する場合は必須)
    - `$snipeItRootUrl`: 登録先Snipe-ITのルートURLを指定 (任意、登録する場合は必須)
    - `$snipeItApiKey`: Snipe-ITで発行したAPI Keyを指定 (任意、登録する場合は必須)
    - `$modelId`: Snipe-ITの型番IDをintで指定 (任意、登録する場合は必須)
    - `$assetName`: Snipe-ITの型番IDをintで指定 (任意)

## 環境

- OS
  - Windows 10 Pro
  - Windows 10 Home
  - Windows Server 2016

## 手順

Launch Power Shell from the context menu "Run as administrator" and execute the following command.
コンテキストメニュー「管理者として実行」からPower Shellを起動し、下記コマンドを実行します。

### 初期設定のみの場合

```:powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process
$VerbosePreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12
iwr -useb raw.githubusercontent.com/shigel/setup-win-min/main/setup-win.ps1 -Headers @{"Cache-Control"="no-cache"} | iex
Setup-Windows
```

### slack通知する場合

```:powershell
$slackWebhookUrl="https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX"
$slackMentionSubteamId="XXXXXXXXXXX"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process
$VerbosePreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12
iwr -useb raw.githubusercontent.com/shigel/setup-win-min/main/setup-win.ps1 -Headers @{"Cache-Control"="no-cache"} | iex
Setup-Windows
```

### Snipe-ITに登録する場合

```:powershell
$snipeItRootUrl = "https://snipe-it.example.com/"
$snipeItApiKey = 'XXXXXXXXXXXXXXXX...XXXXXXXXXXXXXXXX'
$modelId = 0
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process
$VerbosePreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12
iwr -useb raw.githubusercontent.com/shigel/setup-win-min/main/setup-win.ps1 -Headers @{"Cache-Control"="no-cache"} | iex
Setup-Windows
```
