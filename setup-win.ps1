# 現在のユーザーアカウントでPowerShellを有効にし、ダイアログが表示されないようにセキュリティを緩める。
# Enable PowerShell for the current user account and loosen the security so that the dialog is not displayed.
$ExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
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

# ssh key generates
# Write-Verbose: 鍵を作成します。上書きする場合は(y)、しない場合は(n)を入力してEnterを押してください。
Write-Verbose: making ssh key. Overwrite(y), Not Overwrite(n) and input Enter key.
mkdir ${HOME}\.ssh\
ssh-keygen -f ${HOME}\.ssh\id_rsa -t rsa -N '""' -q

# no dialog for ssh fingerprint
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

# ユーザーアカウントのPowerShell実行ポリシーを復元する
# Restore the PowerShell execution policy for a user account.
Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope CurrentUser

#Read-Host "初期設定が完了しました。このあと公開鍵の内容が表示されます。`nGithubなどのDeploy Keyに設定してください。"
Read-Host "Finished init configuration. showing public key.`nSet Deploy Key. ex) Github"

cat ${HOME}\.ssh\id_rsa.pub
