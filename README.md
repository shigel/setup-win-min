# setup-win-min

## 概要

PowerShellから自動で環境構築できるよう、最低限の設定を行う。

## 環境

- OS
    - Windows 10 Pro
    - Windows Server 2016

## 手順

Launch Power Shell from the context menu "Run as administrator" and execute the following command.
コンテキストメニュー「管理者として実行」からPower Shellを起動し、下記コマンドを実行します。

```:powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process
$VerbosePreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12
iwr -useb raw.githubusercontent.com/shigel/setup-win-min/main/setup-win.ps1 | iex
```
