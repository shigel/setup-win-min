# ���݂̃��[�U�[�A�J�E���g��PowerShell��L���ɂ��A�_�C�A���O���\������Ȃ��悤�ɃZ�L�����e�B���ɂ߂�B
# Enable PowerShell for the current user account and loosen the security so that the dialog is not displayed.
$ExecutionPolicy = Get-ExecutionPolicy -Scope Process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process

# Invoke-WebRequest�̑��x���P
$ProgressPreference = 'SilentlyContinue'

$WindowsInfo = $null
$WindowsInfoString = ""

function Send-Slack{
    param(
        [Parameter(Mandatory,Position=1)]
        [string]$slackMessage,

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
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($mentionSubteamId + $slackMessage)

    # Json�ɕϊ�����
    $payload = @{ 
        text = $encode.GetString($utf8Bytes);

        # Slack��WebHook��BOT���ƃA�C�R�����w�肵�Ă���ꍇ�͉��L�X�N���v�g�͕s�v
        #username = "PowerShell BOT";
        #icon_url = "https://xxxx/xxx.png";
    }

    if([string]::IsNullOrEmpty($slackWebhookUrl)) {
        Write-Output $slackMessage
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

function PostHardwareSnipeIt2 {
    param(
        [Parameter(Mandatory,Position=1)]
        [string]$snipeItRootUrl,

        [Parameter(Mandatory,Position=2)]
        [string]$snipeItApiKey,

        [Parameter(Mandatory=$false,Position=3)]
        [string]$assetName,

        [Parameter(Mandatory,Position=4)]
        [string]$assetTag,

        [Parameter(Mandatory,Position=5)]
        [System.Object]$WindowsInfo
    )

    # Registration to Snipe-IT
    Install-Module SnipeitPS -Force
    Import-Module SnipeitPS

    $serialNumber = $WindowsInfo.SerialNumber

    $modelName = $WindowsInfo.Model

    $manufacturerName = $WindowsInfo.Manufacturer
    
    $WindowsInfoString = ($WindowsInfo | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Definition) -join "`r`n"

    $manufacturerId = $null
    $manufacturers = Get-SnipeitManufacturer -search $manufacturerName
    if ($manufacturers.total -eq 0) {
        $SnipeitManufacturer = New-SnipeitManufacturer -name $manufacturerName
        $SnipeitManufacturer
        $manufacturerId = $SnipeitManufacturer.id
    } else {
        $manufacturerId = $manufacturers[0].id
    } 

    $modelId = $null
    $models = Get-SnipeitModel -search $modelName
    if ($models.total -eq 0) {
        $SnipeitModel = New-SnipeitModel -name $modelName -manufacturer_id $manufacturerId -fieldset_id 1 -category_id 1
        $SnipeitModel
        $modelId = $SnipeitModel.id
    } else {
        $modelId = $models[0].id
    } 

    $snipeitMessages = PostHardwareSnipeIt $snipeItRootUrl $snipeItApiKey $modelId $assetName $assetTag $serialNumber -notes "$WindowsInfoString"
    return $snipeitMessages
}

function PostHardwareSnipeIt {
    param(
        [Parameter(Mandatory,Position=1)]
        [string]$snipeItRootUrl,

        [Parameter(Mandatory,Position=2)]
        [string]$snipeItApiKey,

        [Parameter(Mandatory,Position=3)]
        [int]$modelId,

        [Parameter(Position=4)]
        [string]$assetName,

        [Parameter(Mandatory,Position=5)]
        [string]$assetTag,

        [Parameter(Mandatory,Position=6)]
        [string]$serialNumber,

        [parameter(mandatory = $false)]
        [string]$notes
    )

    $statusId = 2     # Ready to Deploy
    # To use each session:
    Set-SnipeitInfo -URL $snipeItRootUrl -apiKey $snipeItApiKey

    $snipeitMessages = New-Object System.Collections.ArrayList

    $assets1 = Get-SnipeitAsset -serial $serialNumber
    $asset2 = Get-SnipeitAsset -asset_tag $assetTag
    if (($null -ne $assets1) -and ($null -ne $assets1.count)-and ($null -eq $assets1[-1].deleted_at)) {
        $snipeitMessages.Add("Serial Number '$serialNumber' is Duplicated. $snipeItRootUrl/hardware/" + $assets1[-1].id)
    }
    if (($null -ne $asset2) -and ($null -ne $asset2.count) -and ($null -eq $asset2.deleted_at)) {
        $snipeitMessages.Add("Asset Tag '$assetTag' is Duplicated. $snipeItRootUrl/hardware/" + $asset2.id)
    }
    if ($snipeitMessages.count -eq 0) {

        $new_asset =
            New-SnipeitAsset $statusId $modelId $assetName -asset_tag $assetTag -serial $serialNumber -notes "$notes"
        $snipeitMessages.Add(
            "Asset Tag '" + $new_asset.asset_tag +"' is created. $snipeItRootUrl/hardware/" + $new_asset.id)
    }

    return ($snipeitMessages -join "`r`n")
}

function Setup {
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
        # else
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

function Setup-Windows {

    try {
        Setup 

        Write-Output "### Initialize is finished. ###"
        $publicKey = Get-Content ${HOME}\.ssh\id_rsa.pub

        $WindowsInfo = GetWindowsInfo
        $serialNumber = $WindowsInfo.SerialNumber
        $WindowsInfoString = ($WindowsInfo | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Definition) -join "`r`n"
        
        $slackMessage = @"
$slackMention
*Initialization is complete. (assetTag:$assetTag)*
-------------------------------
Please set the public key to the Deploy Key of Github, etc.
### Public Key:
``````
$publicKey
``````
### Windows Infomation:
``````
$WindowsInfoString
``````
"@

        if ([string]::IsNullOrEmpty($snipeItRootUrl) -or [string]::IsNullOrEmpty($snipeItApiKey)) {
            # nothing to do
        } else {
            $snipeitMessages = PostHardwareSnipeIt2 $snipeItRootUrl $snipeItApiKey -assetName "$assetName" -assetTag $assetTag -WindowsInfo $WindowsInfo
            # $snipeitMessages = (PostHardwareSnipeIt $snipeItRootUrl $snipeItApiKey $modelId "$assetName" $assetTag $serialNumber -notes "$WindowsInfoString") -join "`r`n"

            $slackMessage += @"
### Snipe-IT Infomation:
``````
$snipeitMessages
``````
"@
        }
        
        if([string]::IsNullOrEmpty($slackWebhookUrl)) {
            Write-Output $slackMessage
        } else {
            Send-Slack $slackMessage $slackWebhookUrl $slackMentionSubteamId
        }
        
    } catch {
        $scriptStackTrace = $_.ScriptStackTrace.toString()
        $slackMessage = @"
$slackMention
*An error occurred! (assetTag:$assetTag)*
-------------------------------
### Script Stack Trace:
``````
$scriptStackTrace
``````
### Windows Infomation
``````
$WindowsInfoString
``````
"@

    if([string]::IsNullOrEmpty($slackWebhookUrl)) {
        Write-Output $slackMessage
    } else {
        Send-Slack $slackMessage $slackWebhookUrl $slackMentionSubteamId
    }
} finally {
    # ���[�U�[�A�J�E���g��PowerShell���s�|���V�[�𕜌�����
    # Restore the PowerShell execution policy for a user account.
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope Process
}

}
