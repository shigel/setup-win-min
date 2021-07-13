# ���[�U�[�A�J�E���g��PowerShell��L���ɂ��A�_�C�A���O���o�Ȃ��悤�ɃZ�L�����e�B���ɂ߂�
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

# ssh���쐬
mkdir ${HOME}
ssh-keygen -f ${HOME}\.ssh\id_rsa -t rsa -N '""'

# ���[�U�[�A�J�E���g��PowerShell�𖳌��ɂ��A�Z�L�����e�B�ݒ�����S�Ȃ��̂ɐݒ肷��
Set-ExecutionPolicy -ExecutionPolicy Restricted -Force -Scope CurrentUser

Read-Host "�����ݒ肪�������܂����B���̂��ƌ��J���̓��e���\������܂��B\nGithub�Ȃǂ�Deploy Key�ɐݒ肵�Ă��������B"

cat ${HOME}\.ssh\id_rsa.pub
