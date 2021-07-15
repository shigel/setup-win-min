﻿# 現在のユーザーアカウントでPowerShellを有効にし、ダイアログが表示されないようにセキュリティを緩める。
# Enable PowerShell for the current user account and loosen the security so that the dialog is not displayed.
$ExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser

try {
    # enabled TLS1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12

    Install-PackageProvider -Force NuGet
    Install-PackageProvider -Force Chocolatey
    Install-PackageProvider -Force ChocolateyGet

    Install-Package -Force GoogleChrome -ProviderName ChocolateyGet

    cd ~
    # Install Scoop
    #Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    if (!(Test-Path scoop)) {
        iwr -useb get.scoop.sh | iex
    }

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
    Write-Output "making ssh key. Overwrite(y), Not Overwrite(n) and input Enter key."
    if (Test-Path ${HOME}\.ssh\id_rsa) {
        Write-Output "The ssh key already exists."
    } elseif (Test-Path ${HOME}\.ssh\) {
        Write-Output "The ${HOME}\.ssh\ directory already exists."
        ssh-keygen -f ${HOME}\.ssh\id_rsa -t rsa -N '""' -q
    } else {
        mkdir ${HOME}\.ssh\
        ssh-keygen -f ${HOME}\.ssh\id_rsa -t rsa -N '""' -q
    }

    # no dialog for ssh fingerprint
    Write-Output "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

    #Read-Host "初期化が完了しました。`nEnterを押すと、公開鍵の内容が表示されます。`nGithubのDeploy Keyなどに設定してください。"
    Read-Host "Initialization is complete.`nWhen you press Enter, the contents of the public key will be displayed.`nPlease set it to the Deploy Key of Github, etc."

    $message = @"
# Congigure your git profile
git config --global user.email "example@example.com"
git config --global user.name "your nickname"
"@
    Write-Output $message

    Get-Content ${HOME}\.ssh\id_rsa.pub

} catch {
    Write-Output "An error occurred:"
    Write-Output $_.ScriptStackTrace
} finally {
    # ユーザーアカウントのPowerShell実行ポリシーを復元する
    # Restore the PowerShell execution policy for a user account.
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope CurrentUser
}
