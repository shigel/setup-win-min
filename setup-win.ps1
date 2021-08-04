# ���݂̃��[�U�[�A�J�E���g��PowerShell��L���ɂ��A�_�C�A���O���\������Ȃ��悤�ɃZ�L�����e�B���ɂ߂�B
# Enable PowerShell for the current user account and loosen the security so that the dialog is not displayed.
$ExecutionPolicy = Get-ExecutionPolicy -Scope Process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process

# Invoke-WebRequest�̑��x���P
$ProgressPreference = 'SilentlyContinue'

function Send-Slack{
    param(
        [Parameter(Mandatory,Position=1)]
        [string]$message,

        [Parameter(Mandatory,Position=2)]
        [string]$webhookUrl,

        [Parameter(Position=3)]
        [string]$mentionSubteamId
    )

    if([string]::IsNullOrEmpty($mentionSubteamId)) {
        $mentionSubteamId = "<!here>"
    } else {
        $mentionSubteamId = "<!subteam^$mentionSubteamId>"
    }

    # ���{��G���R�[�h�p
    $encode = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($mentionSubteamId + $message)

    # Json�ɕϊ�����
    $payload = @{ 
        text = $encode.GetString($utf8Bytes);

        # Slack��WebHook��BOT���ƃA�C�R�����w�肵�Ă���ꍇ�͉��L�X�N���v�g�͕s�v
        #username = "PowerShell BOT";
        #icon_url = "https://xxxx/xxx.png";
    }

    if([string]::IsNullOrEmpty($slackWebhookUrl)) {
        Write-Output $message
    } else {
        # Slack��REST API��������
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (ConvertTo-Json $payload)
    }
}

#####################################################################
# �V�X�e�����
#####################################################################
function GetWindowsInfo {
    $WindowsInfo = New-Object PSObject `
        | Select-Object HostName,GlobalIP,UserName,Manufacturer,Model,SerialNumber,CPUName,PhysicalCores,Sockets,MemorySize,DiskInfos,OS

    $Win32_BIOS = Get-WmiObject Win32_BIOS
    $Win32_Processor = Get-WmiObject Win32_Processor
    $Win32_ComputerSystem = Get-WmiObject Win32_ComputerSystem
    $Win32_OperatingSystem = Get-WmiObject Win32_OperatingSystem

    # �z�X�g��
    $WindowsInfo.HostName = hostname

    # �O���[�o��IP�A�h���X
    $json = (Invoke-WebRequest -Uri "ipinfo.io" -UseBasicParsing).Content
    $WindowsInfo.GlobalIP = (ConvertFrom-Json $json).ip

    # ���[�U��
    $WindowsInfo.UserName = $env:UserName

    # ���[�J�[��
    $WindowsInfo.Manufacturer = $Win32_BIOS.Manufacturer

    # ���f����
    $WindowsInfo.Model = $Win32_ComputerSystem.Model

    # �V���A���ԍ�
    $WindowsInfo.SerialNumber = $Win32_BIOS.SerialNumber

    # CPU ��
    $WindowsInfo.CPUName = @($Win32_Processor.Name)[0]

    # �����R�A��
    $PhysicalCores = 0
    $Win32_Processor.NumberOfCores | % { $PhysicalCores += $_}
    $WindowsInfo.PhysicalCores = $PhysicalCores
    
    # �\�P�b�g��
    $WindowsInfo.Sockets = $Win32_ComputerSystem.NumberOfProcessors
    
    # �������[�T�C�Y(GB)
    $Total = 0
    Get-WmiObject -Class Win32_PhysicalMemory | % {$Total += $_.Capacity}
    $WindowsInfo.MemorySize = [int]($Total/1GB)
    
    # �f�B�X�N���
    [array]$DiskDrives = Get-WmiObject Win32_DiskDrive | ? {$_.Caption -notmatch "Msft"} | sort Index
    $DiskInfos = @()
    foreach( $DiskDrive in $DiskDrives ){
        $DiskInfo = New-Object PSObject | Select-Object Index, DiskSize
        $DiskInfo.Index = $DiskDrive.Index              # �f�B�X�N�ԍ�
        $DiskInfo.DiskSize = [int]($DiskDrive.Size/1GB) # �f�B�X�N�T�C�Y(GB)
        $DiskInfos += $DiskInfo
    }
    $WindowsInfo.DiskInfos = $DiskInfos
    
    # OS 
    $OS = $Win32_OperatingSystem.Caption
    $SP = $Win32_OperatingSystem.ServicePackMajorVersion
    if( $SP -ne 0 ){ $OS += "SP" + $SP }
    $WindowsInfo.OS = $OS
    
    return $WindowsInfo
}

function main {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser
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

    # Restore the PowerShell execution policy for a user account.
    # Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope CurrentUser
    # Write-Output "ExecutionPolicy��${ExecutionPolicy}����RemoteSigned�ɕύX����܂����B"
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope Process
}

try {
    main 

    Write-Output "### Initialize is finished. ###"
    $publicKey = Get-Content ${HOME}\.ssh\id_rsa.pub
    $WindowsInfo = (GetWindowsInfo | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Definition) -join "`r`n"
    
$message = @"
$slackMention
*Initialization is complete. (assetTag:$assetTag)*
-------------------------------
Please set the public key to the Deploy Key of Github, etc.
### publicKey:
``````
$publicKey
``````
### Windows Infomation
``````
$WindowsInfo
``````
"@

    if([string]::IsNullOrEmpty($slackWebhookUrl)) {
        Write-Output $message
    } else {
        Send-Slack $message $slackWebhookUrl $slackMentionSubteamId
    }
    
} catch {
    $WindowsInfo = (GetWindowsInfo | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Definition) -join "`r`n"
    
    # $message = "`<!here>`nAn error occurred: `n*assetTag: $assetTag*`n``````" + $_.ScriptStackTrace.toString() + "`n```````n``````$WindowsInfo``````"
    $scriptStackTrace = $_.ScriptStackTrace.toString()
    $message = @"
$slackMention
*An error occurred! (assetTag:$assetTag)*
-------------------------------
### Script Stack Trace:
``````
$scriptStackTrace
``````
### Windows Infomation
``````
$WindowsInfo
``````
"@

    if([string]::IsNullOrEmpty($slackWebhookUrl)) {
        Write-Output $message
    } else {
        Send-Slack $message $slackWebhookUrl $slackMentionSubteamId
    }
} finally {
    # ���[�U�[�A�J�E���g��PowerShell���s�|���V�[�𕜌�����
    # Restore the PowerShell execution policy for a user account.
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope Process
}
