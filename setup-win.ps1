# ���݂̃��[�U�[�A�J�E���g��PowerShell��L���ɂ��A�_�C�A���O���\������Ȃ��悤�ɃZ�L�����e�B���ɂ߂�B
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
# Write-Verbose: �����쐬���܂��B�㏑������ꍇ��(y)�A���Ȃ��ꍇ��(n)����͂���Enter�������Ă��������B
Write-Verbose: making ssh key. Overwrite(y), Not Overwrite(n) and input Enter key.
mkdir ${HOME}\.ssh\
ssh-keygen -f ${HOME}\.ssh\id_rsa -t rsa -N '""' -q

# no dialog for ssh fingerprint
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

# ���[�U�[�A�J�E���g��PowerShell���s�|���V�[�𕜌�����
# Restore the PowerShell execution policy for a user account.
Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope CurrentUser

#Read-Host "�����ݒ肪�������܂����B���̂��ƌ��J���̓��e���\������܂��B`nGithub�Ȃǂ�Deploy Key�ɐݒ肵�Ă��������B"
Read-Host "Finished init configuration. showing public key.`nSet Deploy Key. ex) Github"

cat ${HOME}\.ssh\id_rsa.pub
