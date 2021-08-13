# 現在のユーザーアカウントでPowerShellを有効にし、ダイアログが表示されないようにセキュリティを緩める。
# Enable PowerShell for the current user account and loosen the security so that the dialog is not displayed.
$ExecutionPolicy = Get-ExecutionPolicy -Scope Process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process

# Invoke-WebRequestの速度改善
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

    # 日本語エンコード用
    $encode = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($mentionSubteamId + $slackMessage)

    # Jsonに変換する
    $payload = @{ 
        text = $encode.GetString($utf8Bytes);

        # SlackのWebHookでBOT名とアイコンを指定している場合は下記スクリプトは不要
        #username = "PowerShell BOT";
        #icon_url = "https://xxxx/xxx.png";
    }

    if([string]::IsNullOrEmpty($slackWebhookUrl)) {
        Write-Output $slackMessage
    } else {
        # SlackのREST APIをたたく
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (ConvertTo-Json $payload)
    }
}

#####################################################################
# システム情報
#####################################################################
function GetWindowsInfo {
    $WindowsInfo = New-Object PSObject `
        | Select-Object HostName,GlobalIP,UserName,Manufacturer,Model,SerialNumber,CPUName,PhysicalCores,Sockets,MemorySize,DiskInfos,OS

    $Win32_BIOS = Get-WmiObject Win32_BIOS
    $Win32_Processor = Get-WmiObject Win32_Processor
    $Win32_ComputerSystem = Get-WmiObject Win32_ComputerSystem
    $Win32_OperatingSystem = Get-WmiObject Win32_OperatingSystem

    # ホスト名
    $WindowsInfo.HostName = hostname

    # グローバルIPアドレス
    $json = (Invoke-WebRequest -Uri "ipinfo.io" -UseBasicParsing).Content
    $WindowsInfo.GlobalIP = (ConvertFrom-Json $json).ip

    # ユーザ名
    $WindowsInfo.UserName = $env:UserName

    # メーカー名
    $WindowsInfo.Manufacturer = $Win32_BIOS.Manufacturer

    # モデル名
    $WindowsInfo.Model = $Win32_ComputerSystem.Model

    # シリアル番号
    $WindowsInfo.SerialNumber = $Win32_BIOS.SerialNumber

    # CPU 名
    $WindowsInfo.CPUName = @($Win32_Processor.Name)[0]

    # 物理コア数
    $PhysicalCores = 0
    $Win32_Processor.NumberOfCores | % { $PhysicalCores += $_}
    $WindowsInfo.PhysicalCores = $PhysicalCores
    
    # ソケット数
    $WindowsInfo.Sockets = $Win32_ComputerSystem.NumberOfProcessors
    
    # メモリーサイズ(GB)
    $Total = 0
    Get-WmiObject -Class Win32_PhysicalMemory | % {$Total += $_.Capacity}
    $WindowsInfo.MemorySize = [int]($Total/1GB)
    
    # ディスク情報
    [array]$DiskDrives = Get-WmiObject Win32_DiskDrive | ? {$_.Caption -notmatch "Msft"} | sort Index
    $DiskInfos = @()
    foreach( $DiskDrive in $DiskDrives ){
        $DiskInfo = New-Object PSObject | Select-Object Index, DiskSize
        $DiskInfo.Index = $DiskDrive.Index              # ディスク番号
        $DiskInfo.DiskSize = [int]($DiskDrive.Size/1GB) # ディスクサイズ(GB)
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

    return $snipeitMessages
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
    $writer = New-Object System.IO.StreamWriter(
        "${HOME}\.ssh\config", 
        $true,
        (New-Object System.Text.UTF8Encoding($false)))
    $writer.WriteLine("Host github.com`r`n`tStrictHostKeyChecking no`r`n")
    $writer.Close()

    # Restore the PowerShell execution policy for a user account.
    # Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope CurrentUser
    # Write-Output "ExecutionPolicyは${ExecutionPolicy}からRemoteSignedに変更されました。"
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope Process
}

try {
    main 

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
        $snipeitMessages = (PostHardwareSnipeIt $snipeItRootUrl $snipeItApiKey $modelId $assetName $assetTag $serialNumber -notes "$WindowsInfoString") -join "`r`n"

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
    # ユーザーアカウントのPowerShell実行ポリシーを復元する
    # Restore the PowerShell execution policy for a user account.
    Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -Scope Process
}
