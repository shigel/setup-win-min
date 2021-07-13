# ユーザーアカウントでPowerShellを有効にし、ダイアログが出ないようにセキュリティを緩める
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser

# enabled TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Force NuGet
Install-PackageProvider -Force Chocolatey
Install-PackageProvider -Force ChocolateyGet

Install-Package -Force GoogleChrome -ProviderName ChocolateyGet

cd ~
# Install Scoop
#Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
iwr -useb get.scoop.sh | iex

# Scoop can utilize aria2 to use multi-connection downloads. Simply install aria2 through Scoop and it will be used for all downloads afterward.
scoop install aria2

# need git for adding bucket
scoop install git

# add bucket
scoop bucket add extras

# add apps
# Win 10 Pro is installed openssh, but Win Server 2016 is not installed openssh
# scoop install openssh

# ssh鍵作成
mkdir ${HOME}
ssh-keygen -f ${HOME}\.ssh\id_rsa -t rsa -N '""'

# ユーザーアカウントでPowerShellを無効にし、セキュリティ設定を安全なものに設定する
Set-ExecutionPolicy -ExecutionPolicy Restricted -Force -Scope CurrentUser

Read-Host "初期設定が完了しました。このあと公開鍵の内容が表示されます。\nGithubなどのDeploy Keyに設定してください。"

cat ${HOME}\.ssh\id_rsa.pub
