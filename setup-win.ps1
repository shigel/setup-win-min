# ���݂̃��[�U�[�A�J�E���g��PowerShell��L���ɂ��A�_�C�A���O���\������Ȃ��悤�ɃZ�L�����e�B���ɂ߂�B
# Enable PowerShell for the current user account and loosen the security so that the dialog is not displayed.
$ExecutionPolicy = Get-ExecutionPolicy -Scope Process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process

# Invoke-WebRequest�̑��x���P
$ProgressPreference = 'SilentlyContinue'

try {
    # enabled TLS1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bOR [Net.SecurityProtocolType]::Tls12

    Install-PackageProvider -Force NuGet
    Install-PackageProvider -Force Chocolatey
    Install-PackageProvider -Force ChocolateyGet

    Install-Package -Force GoogleChrome -ProviderName ChocolateyGet

    cd ${HOME}
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

    # add Openssh
    $OSVersion = [System.Environment]::OSVersion.Version
    Write-Output "Windows OS Version is " $OSVersion.ToString()
    if (($OSVersion.Major -ne 10) -or ($OSVersion.Major -ne 10)) {
        # Windows 10 Pro
        # Windows 10 Pro is installed openssh
        Write-Output "This program supports Windows 10 Pro and Windows Server 2016."
        exit
    } elseif ($OSVersion.Build -eq 19042) {
        # Windows 10 Pro
        # Windows 10 Pro is installed openssh
    } elseif ($OSVersion.Build -eq 14393) {
        # Windows Server 2016 is not installed openssh
        scoop install openssh
    }

    # ssh key generates
    # Write-Verbose: �����쐬���܂��B�㏑������ꍇ��(y)�A���Ȃ��ꍇ��(n)����͂���Enter�������Ă��������B
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
    $writer = New-Object System.IO.StreamWriter(
        "${HOME}\.ssh\config", 
        $true,
        (New-Object System.Text.UTF8Encoding($false)))
    $writer.WriteLine("Host github.com`r`n`tStrictHostKeyChecking no`r`n")
    $writer.Close()

    #Read-Host "���������������܂����B`r`nEnter�������ƁA���J���̓��e���\������܂��B`r`nGithub��Deploy Key�Ȃǂɐݒ肵�Ă��������B"
    $message = @"
Initialization is complete.
When you press Enter, the contents of the public key will be displayed.
Please set it to the Deploy Key of Github, etc.
"@
    Read-Host $message

    $message = @"
# Congigure your git profile
git config --global user.email "example@example.com"
git config --global user.name "your nickname"
--------------------------------
"@
    Write-Output $message

    Get-Content ${HOME}\.ssh\id_rsa.pub

} catch {
    Write-Output "An error occurred:"
    Write-Output $_.ScriptStackTrace
} finally {
    # ���[�U�[�A�J�E���g��PowerShell���s�|���V�[�𕜌�����
    # Restore the PowerShell execution policy for a user account.
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope Process
}
