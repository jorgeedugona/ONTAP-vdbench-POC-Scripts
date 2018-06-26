##########################################################
##########################################################
##########################################################
# Copyright (c) 2018 NetApp, Inc. All rights reserved.
# Specifications subject to change without notice.
#
# This sample code is provided AS IS, with no support or
# warranties of any kind, including but not limited to
# warranties of merchantability or fitness of any kind,
# expressed or implied.
# 
# PowerShell Version = 5.0
# NetApp Powershell toolkit = 4.5 
# Min Ontap Version = 9.0
# Min ESXi Version = 6.0
# vdbench Version = 5.04.06
# PowerCLI Version = 6.5
# POSHSSH Version = 1.7.7
#
#
# Author: Jorge E Gomez Navarrete gjorge@netapp.com
##########################################################
##########################################################
##########################################################
 
Function Configfile($Global:PathNameFiles){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

Clear-Host

if($Global:config.other.NFS){

NFSDeployment

}elseif($Global:config.other.iSCSI){

iSCSIDeployment


}elseif($Global:config.other.FC){

FCPDeployment

}else{


Write-Log "==============================================================" -Path $LogFileName -Level Warn
Write-Log " NFS, iSCSI and FCP flags are set to False in the Config file " -Path $LogFileName -Level Warn
Write-Log "==============================================================" -Path $LogFileName -Level Warn
Write-Log " " -Path $LogFileName -Level Warn
}

}
 
Function NFSDeployment{

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_Prefix = "NFS"

Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log "                       NFS Deployment                     " -Path $LogFileName -Level Info
Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info

#Connecting to VCenter....

$ConnetionVCenter = Connect-Vcenter $ConnectedVcenter -LogFilePath $LogFileName

if($ConnetionVCenter -eq "Stop"){

    Write-Log "We failed to connected to Vcenter $ConnectedVcenter" -Path $LogFileName -Level Error 
    Return "FailConnection"
    Break
}

#Connecting to NetApp Controller.....

$ConnectionNetApp = Connect-NetApp $global:CurrentNcController -LogFilePath $LogFileName

if($ConnectionNetApp -eq "Stop"){
    
    Write-Log "We failed to connected to NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "FailConnection"
    Break
}

Write-Log "Creation of the SVM......" -Path $LogFileName -Level Info

$SVMCreation  = New-ncVserverVD2($SVM_Prefix)
if($SVMCreation -eq "SVM_Already_exist"){
    
    Write-Log "SVM Could not be created in NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "SVM_Already_exist"
    Break
}

Write-Log "Creation of the Data LIFS......" -Path $LogFileName -Level Info

DataLifsSVM($SVM_Prefix)

Write-Log "Creation of the NFS DataStore..... " -Path $LogFileName -Level Info

#This function can only be run one time.
 
$DataStores = Get-Datastore

if($DataStores.Name -notcontains $Global:config.VMsLIF.lif0.Name){
        
        Write-Log "Creation of the DataStore LIF......" -Path $LogFileName -Level Info
        
        DataStoreLifs($SVM_Prefix)
        
        $DataLIFS = Mount-NFSDatastore2($SVM_Prefix)
        if($DataLIFS -eq "DATALIFSDOWN"){
        Return "DATALIFSDOWN"
        Break
        }

        Write-Log "Importing the OVA......" -Path $LogFileName -Level Info
       
        Import-OVA2 $PSScriptRoot $SVM_Prefix

        Write-Log "Importing the VM Profiles......" -Path $LogFileName -Level Info

        Import-Specsvdbench2($SVM_Prefix)

        Write-Log "Cloning and Turning ON VMS......" -Path $LogFileName -Level Info

        Create-VMsvdbench2($SVM_Prefix)

        Write-Log "Configuring DNS on VMs......" -Path $LogFileName -Level Info

        Config-DNSVM2($SVM_Prefix)

        Write-Log "Creating SharedVols VolS......" -Path $LogFileName -Level Info

        Shared-Files $SVM_Prefix $PSScriptRoot

}

Write-Log "Creating NFS VolS......" -Path $LogFileName -Level Info

$NFSVolCreation = Create-NFSVol2

if($NFSVolCreation -eq "IssuesWithVMs" -or $NFSVolCreation -eq "CancelNFSVols"){
    
    Write-Log "NFS Vols Could not be created in NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Warn
    Return "IssuesWithVMs"
    Break
}

Write-Log "Changing Config Files NFS VolS......" -Path $LogFileName -Level Info

#NFS - vdbench config files.
Config-VMNFSFiles2

Write-Log "Creating vdbench Files......" -Path $LogFileName -Level Info

vdbench-Files2($SVM_Prefix)
}
 
Function iSCSIDeployment{

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_Prefix = "iSCSI"

Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log "                    iSCSI Deployment                      " -Path $LogFileName -Level Info
Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
    
#Connecting to VCenter....

$ConnetionVCenter = Connect-Vcenter $ConnectedVcenter -LogFilePath $LogFileName

if($ConnetionVCenter -eq "Stop"){

    Write-Log "We failed to connected to Vcenter $ConnectedVcenter" -Path $LogFileName -Level Error 
    Return "FailConnection"
    Break
}


#Connecting to NetApp Controller.....

$ConnectionNetApp = Connect-NetApp $global:CurrentNcController -LogFilePath $LogFileName

if($ConnectionNetApp -eq "Stop"){
    
    Write-Log "We failed to connected to NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "FailConnection"
    Break
}

Write-Log "Creation of the SVM......" -Path $LogFileName -Level Info

$SVMCreation  = New-ncVserverVD2($SVM_Prefix)
if($SVMCreation -eq "SVM_Already_exist"){
    
    Write-Log "SVM Could not be created in NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "SVM_Already_exist"
    Break
}

Write-Log "Creation of the Data LIFS......" -Path $LogFileName -Level Info

DataLifsSVM($SVM_Prefix)

Write-Log "Creation of the iSCSI DataStore..... " -Path $LogFileName -Level Info

#This function can only be run one time. 
$DataStores = Get-Datastore

if($DataStores.Name -notcontains $Global:config.VMsLIF.lif0.Name){
        
        Write-Log "Creation of the DataStore LIF......" -Path $LogFileName -Level Info
        
        DataStoreLifs($SVM_Prefix)

        $DataLIFS = Mount-iSCSI-FCP-Datastore2($SVM_Prefix)
        if($DataLIFS -eq "DATALIFSDOWN"){
        Return "DATALIFSDOWN"
        Break
        }

        Write-Log "Next Step is Importing the OVA......" -Path $LogFileName -Level Info
       
        Import-OVA2 $PSScriptRoot $SVM_Prefix

        Write-Log "Next Step is Importing the VM Profiles......" -Path $LogFileName -Level Info

        Import-Specsvdbench2($SVM_Prefix)

        Write-Log "Next Step is Cloning and Turning ON VMS......" -Path $LogFileName -Level Info

        Create-VMsvdbench2($SVM_Prefix)

        Write-Log "Configuring DNS on VMs......" -Path $LogFileName -Level Info

        Config-DNSVM2($SVM_Prefix)

        Write-Log "Next Step Creating SharedVols VolS......" -Path $LogFileName -Level Info

        Shared-Files $SVM_Prefix $PSScriptRoot

}

Write-Log "Creating iSCSI LUNs......" -Path $LogFileName -Level Info

$LUNsCreation = Create-iSCSI-FC-Lun2($SVM_Prefix)

if($LUNsCreation -eq "IssuesWithVMs" -or $LUNsCreation -eq "CancelLunsVols"){
    
    Write-Log "LUN Vols could not be created in NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "IssuesWithVMs"
    Break
}

Write-Log "Creating RDM disks......" -Path $LogFileName -Level Info

Create-RDMLun2

Write-Log "Creating vdbench Files......" -Path $LogFileName -Level Info

vdbench-Files2($SVM_Prefix)


}
 
Function FCPDeployment{

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_Prefix = "FCP"

Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log "                    FCP Deployment                        " -Path $LogFileName -Level Info
Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
    
#Connecting to VCenter....

$ConnetionVCenter = Connect-Vcenter $ConnectedVcenter -LogFilePath $LogFileName

if($ConnetionVCenter -eq "Stop"){

    Write-Log "We failed to connected to Vcenter $ConnectedVcenter" -Path $LogFileName -Level Error 
    Return "FailConnection"
    Break
}


#Connecting to NetApp Controller.....

$ConnectionNetApp = Connect-NetApp $global:CurrentNcController -LogFilePath $LogFileName

if($ConnectionNetApp -eq "Stop"){
    
    Write-Log "We failed to connected to NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "FailConnection"
    Break
}

Write-Log "Creation of the SVM......" -Path $LogFileName -Level Info

$SVMCreation  = New-ncVserverVD2($SVM_Prefix)
if($SVMCreation -eq "SVM_Already_exist"){
    
    Write-Log "SVM Could not be create in NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "SVM_Already_exist"
    Break
}



Write-Log "Creation of the Data LIFS......" -Path $LogFileName -Level Info

DataLifsSVM($SVM_Prefix)

Write-Log "Creation of the FC DataStore..... " -Path $LogFileName -Level Info

#This function can only be run one time. 
$DataStores = Get-Datastore

if($DataStores.Name -notcontains $Global:config.VMsLIF.lif0.Name){
        
        Write-Log "Creation of the DataStore LIF......" -Path $LogFileName -Level Info
        
        DataStoreLifs($SVM_Prefix)

        $DataLIFS = Mount-iSCSI-FCP-Datastore2($SVM_Prefix)
        if($DataLIFS -eq "DATALIFSDOWN"){
        Return "DATALIFSDOWN"
        Break
        }

        Write-Log "Next Step is Importing the OVA......" -Path $LogFileName -Level Info
       
        Import-OVA2 $PSScriptRoot $SVM_Prefix

        Write-Log "Next Step is Importing the VM Profiles......" -Path $LogFileName -Level Info

        Import-Specsvdbench2($SVM_Prefix)

        Write-Log "Next Step is Cloning and Turning ON VMS......" -Path $LogFileName -Level Info

        Create-VMsvdbench2($SVM_Prefix)

        Write-Log "Configuring DNS on VMs......" -Path $LogFileName -Level Info

        Config-DNSVM2($SVM_Prefix)

        Write-Log "Next Step Creating SharedVols VolS......" -Path $LogFileName -Level Info

        Shared-Files $SVM_Prefix $PSScriptRoot

}

Write-Log "Creating FC LUNs......" -Path $LogFileName -Level Info

$LUNsCreation = Create-iSCSI-FC-Lun2($SVM_Prefix)

if($LUNsCreation -eq "IssuesWithVMs" -or $LUNsCreation -eq "CancelLunsVols"){
    
    Write-Log "LUN Vols could not be created in NetApp Controller $global:CurrentNcController" -Path $LogFileName -Level Error
    Return "IssuesWithVMs"
    Break
}

Write-Log "Creating RDM disks......" -Path $LogFileName -Level Info

Create-RDMLun2

Write-Log "Creating vdbench Files......" -Path $LogFileName -Level Info

vdbench-Files2($SVM_Prefix)

Write-Log "Deployment has Finished......" -Path $LogFileName -Level Info

} 
  
Function Write-Log { 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true)] 
        [Alias("LogContent")] 
        [string[]]$Message, 

        [Parameter(Mandatory=$false)]
        [Alias("LogContent2")] 
        [string[]]$Message2,

        [Parameter(Mandatory=$false,
                    ValueFromPipeline=$true)]
        [Alias("LogContent3")] 
        [string[]]$Message3,
 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]  
        [Alias('LogPath')]
        [string]$Path, 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
        
            # Write message to error, warning, or verbose pipeline and specify $LevelText
            $Message=$Message+$Message2+" "+$Message3
            switch ($Level) { 
                'Error' { 
                    Write-Host $Message -ForegroundColor Red
                    $LevelText = 'ERROR:' 
                    } 
                'Warn' { 
                    Write-Host $Message -ForegroundColor Yellow 
                    $LevelText = 'WARNING:' 
                    } 
                'Info' { 
                    Write-Host $Message -ForegroundColor Green
                    $LevelText = 'INFO:' 
                    } 
                }  
         
            # Write log entry to $Path 
            "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append          
    } 
    End 
    { 
    } 
}
 
function Import-ConfigFile ($Global:PathNameFiles){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$GlobalObject = Get-Content -Path $ConfigFilePath -Raw -ErrorAction SilentlyContinue | ConvertFrom-JSON

################################################################
################################################################
################################################################

$Global:config = @{}

$Global:config.Other = @{}

$Global:config.Other.Add('VCenterIP',$GlobalObject.Other.VCenterIP.Trim())
$Global:config.Other.Add('ClusterIP',$GlobalObject.Other.ClusterIP.Trim())
$Global:config.Other.Add('NumberofVolumesPerVM',$GlobalObject.Other.NumberofVolumesPerVM.Trim())

$Numberperhost = $GlobalObject.Other.NumberVMperhost.Trim()

$Global:config.Other.Add('NumberVMperhost',[int]$Numberperhost)

$VolumeSize = $GlobalObject.Other.VolumeSize.Trim()

$Global:config.Other.Add('VolumeSize',$VolumeSize+"GB")

if($GlobalObject.Other.DSwitch -eq 'true'){
$Global:config.Other.Add('DSwitch',$true)
}else{
$Global:config.Other.Add('DSwitch',$false)
}

$Global:config.Other.Add('PortGroupName',$GlobalObject.Other.PortGroupName.Trim())
$Global:config.Other.Add('NetworkName',$GlobalObject.Other.NetworkName.Trim())

$FileZise = $GlobalObject.Other.FileSize.Trim()

$Global:config.Other.Add('FileSize',$FileZise+"g")

if($GlobalObject.Other.Jumbo -eq 'true'){
$Global:config.Other.Add('Jumbo',$true)
}else{
$Global:config.Other.Add('Jumbo',$false)
}

if($GlobalObject.Other.NFS -eq 'true'){
$Global:config.Other.Add('NFS',$true)
$SVM_Prefix = "NFS"
}else{
$Global:config.Other.Add('NFS',$false)
}

if($GlobalObject.Other.iSCSI -eq 'true'){
$Global:config.Other.Add('iSCSI',$true)
$SVM_Prefix = "iSCSI"
}else{
$Global:config.Other.Add('iSCSI',$false)
}

if($GlobalObject.Other.FC -eq 'true'){
$Global:config.Other.Add('FC',$true)
$SVM_Prefix = "FCP"
}else{
$Global:config.Other.Add('FC',$false)
}

$Global:config.Other.Add('LunID',$GlobalObject.Other.LunID.Trim())
$Global:config.Other.Add('Pathvdbench',$GlobalObject.Other.Pathvdbench.Trim())
$Global:config.Other.Add('PathOVA',$GlobalObject.Other.PathOVA.Trim())

$Global:config.SVM = @{}

$Global:config.SVM.Add('Name',$GlobalObject.SVM.Name.Trim())

$GlobalObject.SVM.Name = $GlobalObject.SVM.Name.Trim()

$Global:config.VMsLIF = @{}
$Global:config.VMsLIF.lif0 = @{}

$Global:config.VMsLIF.lif0.Add('Name',$GlobalObject.SVM.Name)
$Global:config.VMsLIF.lif0.Add('IP',$GlobalObject.VMsLIF.lif0.IP.Trim())
$Global:config.VMsLIF.lif0.Add('Gateway',$GlobalObject.VMsLIF.lif0.Gateway.Trim())
$Global:config.VMsLIF.lif0.Add('Netmask',$GlobalObject.VMsLIF.lif0.Netmask.Trim())
$Global:config.VMsLIF.lif0.Add('Port',$GlobalObject.VMsLIF.lif0.Port.Trim())

$Global:config.VMsLIF.lif1 = @{}

$Global:config.VMsLIF.lif1.Add('Name',$GlobalObject.SVM.Name+"_FC")
$Global:config.VMsLIF.lif1.Add('Port',$GlobalObject.VMsLIF.lif1.Port.Trim())

$Global:config.LIFSNFS = @{}
$Global:config.LIFSNFS.lif1 = @{}
$Global:config.LIFSNFS.lif2 = @{}
$Global:config.LIFSNFS.lif3 = @{}
$Global:config.LIFSNFS.lif4 = @{}

$Global:config.LIFSNFS.lif1.Add('Name',$GlobalObject.SVM.Name+"_nfs_node01-lif-1")
$Global:config.LIFSNFS.lif1.Add('IP',$GlobalObject.LIFSNFS.lif1.IP.Trim())
$Global:config.LIFSNFS.lif1.Add('Gateway',$GlobalObject.LIFSNFS.lif1.Gateway.Trim())
$Global:config.LIFSNFS.lif1.Add('Netmask',$GlobalObject.LIFSNFS.lif1.Netmask.Trim())
$Global:config.LIFSNFS.lif1.Add('Port',$GlobalObject.LIFSNFS.lif1.Port.Trim())

$Global:config.LIFSNFS.lif2.Add('Name',$GlobalObject.SVM.Name+"_nfs_node01-lif-2")
$Global:config.LIFSNFS.lif2.Add('IP',$GlobalObject.LIFSNFS.lif2.IP.Trim())
$Global:config.LIFSNFS.lif2.Add('Gateway',$GlobalObject.LIFSNFS.lif1.Gateway.Trim())
$Global:config.LIFSNFS.lif2.Add('Netmask',$GlobalObject.LIFSNFS.lif1.Netmask.Trim())
$Global:config.LIFSNFS.lif2.Add('Port',$GlobalObject.LIFSNFS.lif2.Port.Trim())

$Global:config.LIFSNFS.lif3.Add('Name',$GlobalObject.SVM.Name+"_nfs_node02-lif-1")
$Global:config.LIFSNFS.lif3.Add('IP',$GlobalObject.LIFSNFS.lif3.IP.Trim())
$Global:config.LIFSNFS.lif3.Add('Gateway',$GlobalObject.LIFSNFS.lif1.Gateway.Trim())
$Global:config.LIFSNFS.lif3.Add('Netmask',$GlobalObject.LIFSNFS.lif1.Netmask.Trim())
$Global:config.LIFSNFS.lif3.Add('Port',$GlobalObject.LIFSNFS.lif3.Port.Trim())

$Global:config.LIFSNFS.lif4.Add('Name',$GlobalObject.SVM.Name+"_nfs_node02-lif-2")
$Global:config.LIFSNFS.lif4.Add('IP',$GlobalObject.LIFSNFS.lif4.IP.Trim())
$Global:config.LIFSNFS.lif4.Add('Gateway',$GlobalObject.LIFSNFS.lif1.Gateway.Trim())
$Global:config.LIFSNFS.lif4.Add('Netmask',$GlobalObject.LIFSNFS.lif1.Netmask.Trim())
$Global:config.LIFSNFS.lif4.Add('Port',$GlobalObject.LIFSNFS.lif4.Port.Trim())

$Global:config.LIFSiSCSI = @{}

$Global:config.LIFSiSCSI.lif5 = @{}
$Global:config.LIFSiSCSI.lif6 = @{}
$Global:config.LIFSiSCSI.lif7 = @{}
$Global:config.LIFSiSCSI.lif8 = @{}

$Global:config.LIFSiSCSI.lif5.Add('Name',$GlobalObject.SVM.Name+"_iscsi_node01-lif-1")
$Global:config.LIFSiSCSI.lif5.Add('IP',$GlobalObject.LIFSiSCSI.lif5.IP.Trim())
$Global:config.LIFSiSCSI.lif5.Add('Gateway',$GlobalObject.LIFSiSCSI.lif5.Gateway.Trim())
$Global:config.LIFSiSCSI.lif5.Add('Netmask',$GlobalObject.LIFSiSCSI.lif5.Netmask.Trim())
$Global:config.LIFSiSCSI.lif5.Add('Port',$GlobalObject.LIFSiSCSI.lif5.Port.Trim())

$Global:config.LIFSiSCSI.lif6.Add('Name',$GlobalObject.SVM.Name+"_iscsi_node01-lif-2")
$Global:config.LIFSiSCSI.lif6.Add('IP',$GlobalObject.LIFSiSCSI.lif6.IP.Trim())
$Global:config.LIFSiSCSI.lif6.Add('Gateway',$GlobalObject.LIFSiSCSI.lif6.Gateway.Trim())
$Global:config.LIFSiSCSI.lif6.Add('Netmask',$GlobalObject.LIFSiSCSI.lif6.Netmask.Trim())
$Global:config.LIFSiSCSI.lif6.Add('Port',$GlobalObject.LIFSiSCSI.lif6.Port.Trim())

$Global:config.LIFSiSCSI.lif7.Add('Name',$GlobalObject.SVM.Name+"_iscsi_node02-lif-1")
$Global:config.LIFSiSCSI.lif7.Add('IP',$GlobalObject.LIFSiSCSI.lif7.IP.Trim())
$Global:config.LIFSiSCSI.lif7.Add('Gateway',$GlobalObject.LIFSiSCSI.lif7.Gateway.Trim())
$Global:config.LIFSiSCSI.lif7.Add('Netmask',$GlobalObject.LIFSiSCSI.lif7.Netmask.Trim())
$Global:config.LIFSiSCSI.lif7.Add('Port',$GlobalObject.LIFSiSCSI.lif7.Port.Trim())

$Global:config.LIFSiSCSI.lif8.Add('Name',$GlobalObject.SVM.Name+"_iscsi_node02-lif-2")
$Global:config.LIFSiSCSI.lif8.Add('IP',$GlobalObject.LIFSiSCSI.lif8.IP.Trim())
$Global:config.LIFSiSCSI.lif8.Add('Gateway',$GlobalObject.LIFSiSCSI.lif8.Gateway.Trim())
$Global:config.LIFSiSCSI.lif8.Add('Netmask',$GlobalObject.LIFSiSCSI.lif8.Netmask.Trim())
$Global:config.LIFSiSCSI.lif8.Add('Port',$GlobalObject.LIFSiSCSI.lif8.Port.Trim())


$Global:config.LIFSFC = @{}

$Global:config.LIFSFC.lif9 = @{}
$Global:config.LIFSFC.lif10 = @{}
$Global:config.LIFSFC.lif11 = @{}
$Global:config.LIFSFC.lif12 = @{}

$Global:config.LIFSFC.lif9.Add('Name',$GlobalObject.SVM.Name+"_FC_node01-lif-1")
$Global:config.LIFSFC.lif9.Add('Port',$GlobalObject.LIFSFC.lif9.Port.Trim())
$Global:config.LIFSFC.lif10.Add('Name',$GlobalObject.SVM.Name+"_FC_node01-lif-2")
$Global:config.LIFSFC.lif10.Add('Port',$GlobalObject.LIFSFC.lif10.Port.Trim())
$Global:config.LIFSFC.lif11.Add('Name',$GlobalObject.SVM.Name+"_FC_node02-lif-1")
$Global:config.LIFSFC.lif11.Add('Port',$GlobalObject.LIFSFC.lif11.Port.Trim())
$Global:config.LIFSFC.lif12.Add('Name',$GlobalObject.SVM.Name+"_FC_node02-lif-2")
$Global:config.LIFSFC.lif12.Add('Port',$GlobalObject.LIFSFC.lif12.Port.Trim())


$Global:config.VMs = @{}
$Global:config.VMs.VM00 = @{}

$Global:config.VMs.VM00.Add('Name',$GlobalObject.SVM.Name+"_"+$SVM_Prefix+"_00")
$Global:config.VMs.VM00.Add('IP',$GlobalObject.VMs.VM00.IP.Trim())
$Global:config.VMs.VM00.Add('Gateway',$GlobalObject.VMs.VM00.Gateway.Trim())
$Global:config.VMs.VM00.Add('Netmask',$GlobalObject.VMs.VM00.Netmask.Trim())



$VMs = $GlobalObject | select -Expand VMs
$Count=1

foreach($item in $VMs | Get-Member | ?{$_.MemberType -eq "NoteProperty"}){


if($item.Name -ne "VM00"){

$ItemName = $item.Name
$NameVariableVM = $ItemName
$Global:config.VMs.$NameVariableVM = @{} 
$Global:config.VMs.$NameVariableVM.Add('Name',$GlobalObject.SVM.Name+"_"+$SVM_Prefix+"_0"+$Count)
$Global:config.VMs.$NameVariableVM.Add('IP',$GlobalObject.VMs.$NameVariableVM.IP)
$Count++
}


}

$Global:config.Hosts = @{}
$Global:config.Hosts.Host00 = @{}
$Global:config.Hosts.Host00.Add('Name',$GlobalObject.Hosts.Host00.Name.Trim())

$Hosts = $GlobalObject | select -Expand Hosts

$Count=1
foreach($item in $Hosts | Get-Member | ?{$_.MemberType -eq "NoteProperty"}){

if($item.Name -ne "Host00"){

$ItemName = $item.Name
$NameVariableHost = $ItemName
$Global:config.Hosts.$NameVariableHost = @{}
$Global:config.Hosts.$NameVariableHost.Add('Name',$GlobalObject.Hosts.$NameVariableHost.Name)
$Count++
}

}


Write-Log "Please find below the Config file imported:" -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
Write-Log "$ConfigFilePath" -Path $LogFileName -Level Info
Write-Log "VMWare  Configuration               " -Path $LogFileName -Level Info
Write-Log "iSCSI is used                     : " $Global:config.Other.iSCSI -Path $LogFileName -Level Info
Write-Log "LUN ID                            : " $Global:config.Other.LunID -Path $LogFileName -Level Info
Write-Log "NFS is used                       : " $Global:config.Other.NFS -Path $LogFileName -Level Info
Write-Log "FCP is used                       : " $Global:config.Other.FC -Path $LogFileName -Level Info
Write-Log "Number of Volumes per VM          : " $Global:config.Other.NumberofVolumesPerVM -Path $LogFileName -Level Info
Write-Log "VCenter IP Address                : " $Global:config.Other.VCenterIP -Path $LogFileName -Level Info
Write-Log "Cluster IP Address                : " $Global:config.Other.ClusterIP -Path $LogFileName -Level Info
if($Global:config.Other.DSwitch){
Write-Log "Network Name                      : " $Global:config.Other.NetworkName -Path $LogFileName -Level Info
}else{
Write-Log "PortGroup Name                    : " $Global:config.Other.PortGroupName -Path $LogFileName -Level Info
}
Write-Log "Number of VMs per Host            : " $Global:config.Other.NumberVMperhost -Path $LogFileName -Level Info
Write-Log "Path vdbench binaries             : " $Global:config.Other.Pathvdbench -Path $LogFileName -Level Info
Write-Log "Path OVA file                     : " $Global:config.Other.PathOVA -Path $LogFileName -Level Info
Write-Log "File Size vdbench                 : " $Global:config.Other.VolumeSize -Path $LogFileName -Level Info
Write-Log "DSwitch is used                   : " $Global:config.Other.DSwitch -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
Write-Log "LIF Configuration for Datatstores : " -Path $LogFileName -Level Info
Write-Log "LIF Name                          : " $Global:config.VMsLIF.lif0.Name -Path $LogFileName -Level Info
Write-Log "LIF IP Address                    : " $Global:config.VMsLIF.lif0.IP -Path $LogFileName -Level Info
Write-Log "LIF Gateway                       : " $Global:config.VMsLIF.lif0.Gateway -Path $LogFileName -Level Info
Write-Log "LIF Netmask                       : " $Global:config.VMsLIF.lif0.Netmask -Path $LogFileName -Level Info
Write-Log "Lif Port                          : " $Global:config.VMsLIF.lif0.Port -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info

if($Global:config.Other.iSCSI){
        Write-Log " " -Path $LogFileName -Level Info        
        Write-Log "LIF Configuration for iSCSI : " -Path $LogFileName -Level Info
        $num = 0
        ForEach($item in $Global:config.LIFSiSCSI.GetEnumerator()){
        Write-Log " " -Path $LogFileName -Level Info
        Write-Log "LIF $num Name        : " $item.Value.Name -Path $LogFileName -Level Info
        Write-Log "LIF $num IP          : " $item.Value.IP -Path $LogFileName -Level Info
        Write-Log "LIF $num Gateway     : " $item.Value.Gateway -Path $LogFileName -Level Info
        Write-Log "LIF $num Netmask     : " $item.Value.Netmask -Path $LogFileName -Level Info
        Write-Log "LIF $num Port        : " $item.Value.Port -Path $LogFileName -Level Info
        Write-Log " " -Path $LogFileName -Level Info
        $num++
        }
                
}elseif($Global:config.Other.NFS){
        Write-Log "LIF Configuration for NFS : " -Path $LogFileName -Level Info
        Write-Log " " -Path $LogFileName -Level Info
        $num = 0
        ForEach($item in $Global:config.LIFSNFS.GetEnumerator()){
        
        Write-Log "LIF $num Name    : " $item.Value.Name -Path $LogFileName -Level Info
        Write-Log "LIF $num IP      : " $item.Value.IP -Path $LogFileName -Level Info
        Write-Log "LIF $num Gateway : " $item.Value.Gateway -Path $LogFileName -Level Info
        Write-Log "LIF $num Netmask : " $item.Value.Netmask -Path $LogFileName -Level Info
        Write-Log "LIF $num Port    : " $item.Value.Port -Path $LogFileName -Level Info
        Write-Log " " -Path $LogFileName -Level Info
        $num++
        }
}elseif($Global:config.Other.FC){

        Write-Log "LIF Configuration for FC : " -Path $LogFileName -Level Info
        Write-Log " " -Path $LogFileName -Level Info
        $num = 0
        ForEach($item in $Global:config.LIFSFC.GetEnumerator()){
        
        Write-Log "LIF $num Name      : " $item.Value.Name -Path $LogFileName -Level Info
        Write-Log "LIF $num port      : " $item.Value.Port -Path $LogFileName -Level Info
        Write-Log " " -Path $LogFileName -Level Info
        $num++
        }
}

Write-Log " " -Path $LogFileName -Level Info
$num = 0
Write-Log "Hosts Configuration : " -Path $LogFileName -Level Info
ForEach($item in $Global:config.Hosts.GetEnumerator()){
Write-Log " " -Path $LogFileName -Level Info
Write-Log "Host $num Name    : " $item.Value.Name -Path $LogFileName -Level Info
$num++

}

$num = 0
Write-Log " " -Path $LogFileName -Level Info
Write-Log "VMs Configuration : " -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
ForEach($item in $Global:config.VMs.GetEnumerator()){

Write-Log "VM $num Name         : " $item.Value.Name -Path $LogFileName -Level Info
Write-Log "VM $num IP           : " $item.Value.IP -Path $LogFileName -Level Info
Write-Log "VM $num Gateway      : " $Global:config.VMs.VM00.Gateway -Path $LogFileName -Level Info
Write-Log "VM $num Netmask      : " $Global:config.VMs.VM00.Netmask -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
$num++
}

Write-Log "Config File was successfully Imported......" -Path $LogFileName -Level Info

}
 
function Connect-Vcenter {
     [CmdletBinding()]
     Param(

     [parameter(Mandatory=$false, 
     HelpMessage="VCenter is connected...",
     ValueFromPipelineByPropertyName=$true)]
     [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]$ConnectedVcenter,

     [parameter(Mandatory=$false)] 
     [string]$LogFilePath

   )

   Begin
   {
   $ipVcenter = $Global:config.Other.VCenterIP
   }

   Process
   {

   if($ConnectedVcenter){
  break
  }
   else{

            Do {
                    # Loop until we get a valid userid/password and can connect, or some other kind of error occurs
                    # $ipVcenter = Read-Host "Please enter the IP/Hostname of VCenter "
                    Write-Log "Connecting to VCenter.......  " -Path $LogFilePath -Level Info
                    $ConnectedVcenter = Connect-VIServer -Server $ipVcenter -WarningAction silentlyContinue -ErrorAction SilentlyContinue -ErrorVariable Err
                    If ($Err.Count -gt 0) {
                            # Some kind of error, figure out if its a bad password
                                    If ($Err.Exception.GetType().Name -eq "InvalidLogin") {
                                        Write-Log "Incorrect user name or password, please try again..." -Path $LogFilePath -Level Error
                                        
                                    }Else{
                                        # Something else went wrong, just display the text and exit
                                        $Error = $Err.Exception
                                        Write-Log "$Error" -Path $LogFilePath -Level Error
                                        return "Stop"
                                        break
                                     }
                            }Else{
                             Write-Log "User name and password are valid.." -Path $LogFilePath -Level Info
                            }
                   
                }
                Until ($Err.Count -eq 0)   
         }
   }

   End
   {
   }

}
 
function Connect-NetApp {
     [CmdletBinding()]
     Param(

     [parameter(Mandatory=$false, 
     HelpMessage="NetApp Controller is connected...",
     ValueFromPipelineByPropertyName=$true)]
     [NetApp.Ontapi.Filer.C.NcController]$global:CurrentNcController,

     [parameter(Mandatory=$false)]
     [string]$LogFilePath

     )

$ipCluster = $Global:config.Other.ClusterIP

   if ($global:CurrentNcController){
                    Write-Log "You are currently connected to " -Path $LogFilePath -Level Info
                    $global:CurrentNcController
                  } else {
                            Do {
                                # Loop until we get a valid userid/password and can connect, or some other kind of error occurs
                                # $ipCluster = Read-Host "Please enter the Management IP of the Ontap Cluster "
                                 Write-Log "Connecting to NetApp Cluster .......  " -Path $LogFilePath -Level Info
                                $Cluster = Connect-NcController $ipCluster -credential (Get-NcCredential) -WarningAction silentlyContinue -ErrorAction SilentlyContinue -ErrorVariable Err
                                         
                                If ($Err.Count -gt 0) {
                                                # Some kind of error, figure out if its a bad password
                                                If (($Err.Exception.GetType().Name -eq "NaConnectionException") -or ($Err.Exception.GetType().Name -eq "NaAuthException")) {
                                                    Write-Log "Incorrect user name or password, please try again... " -Path $LogFilePath -Level Error
                                                    
                                                    }Else{
                                                     # Something else went wrong, just display the text and exit
                                                     $Error = $Err.Exception
                                                     Write-Log $Error -Path $LogFilePath -Level Warn
                                                     return "Stop"
                                                     break 
                                                   }
                                        }Else{
                                        Write-Log "User name and password are valid.." -Path $LogFilePath -Level Info
                                        }
                                }
                          Until ($Err.Count -eq 0)
                        }


}
 
Function New-ncVserverVD2 ($SVM_Prefix) {

   # $Global:PathNameFiles is an array
   # $Global:PathNameFiles[0] is the Configuratiton path.
   # $Global:PathNameFiles[1] is the log name.

   $ConfigFilePath = $Global:PathNameFiles[0]
   $LogFileName = $Global:PathNameFiles[1]

   $Vservers = Get-NcVserver -ErrorVariable Err -ErrorAction SilentlyContinue

   $SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

   if ($Vservers.Vserver -contains $SVM_NAME){
        Write-Log "SVM under the name $SVM_NAME already exists, please delete it by choosing " -Path $LogFileName -Level Warn
        Write-Log "the delete option from the main Menu " -Path $LogFileName -Level Warn
        Return "SVM_Already_exist"
        Break

        }else{
        # create a new SVM

        if($SVM_Prefix -eq "iSCSI"){
                
        $AllowProtocols = "nfs","iscsi"
                
        }elseif($SVM_Prefix -eq "NFS"){

        $AllowProtocols = "nfs"
                
        }elseif($SVM_Prefix -eq "FCP"){
                
        $AllowProtocols = "nfs","fcp"
                
        }
        $selection = Get-NcAggr -ErrorVariable +Err -ErrorAction SilentlyContinue | ?{ $_.AggrRaidAttributes.HasLocalRoot -eq $false }
        #Creating SVM 
        New-NcVserver -Name $SVM_NAME -RootVolume "vdbench_root" `
                        -RootVolumeAggregate $selection[0].Name -RootVolumeSecurityStyle "unix" `
                        -Language "C.UTF-8" -NameServerSwitch "file" `
                        -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        #Configuring the SVM Server
        Set-NcVserver -Name $SVM_NAME -Aggregates $selection[0].Name, $selection[1].Name `
                        -AllowedProtocols $AllowProtocols `
                        -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null                
   }

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
   
}
 
Function DataStoreLifs($SVM_Prefix){

$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

#Delete the Lifs in case the Script was run before. 
$CurrentLifs = Get-NcNetInterface -Vserver $SVM_NAME -Name "$SVM_NAME*" -ErrorVariable Err -ErrorAction SilentlyContinue

        if($CurrentLifs.Count -gt 0){

        Set-NcNetInterface -Name "$SVM_NAME*" -Vserver "$SVM_NAME" `
                           -AdministrativeStatus down -Confirm:$false `
                           -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        Remove-NcNetInterface -Name "$SVM_NAME*" -Vserver "$SVM_NAME" -Confirm:$false `
                              -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        Remove-NcNetRoute -Destination 0.0.0.0/0 -Gateway $Global:config.VMsLIF.lif0.Gateway  `
                          -Metric 20 -VserverContext "$SVM_NAME" -Confirm:$false `
                          -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        }
        # Create the Lifs
        # Get the Nodes of the HA
        $Nodes = Get-NcNode -ErrorVariable +Err -ErrorAction SilentlyContinue
        $CurrentRoute = Get-NcNetRoute -Vserver "$SVM_NAME" -ErrorVariable +Err -ErrorAction SilentlyContinue
        if(!$CurrentRoute){
        New-NcNetRoute -Destination 0.0.0.0/0 -Gateway $Global:config.VMsLIF.lif0.Gateway `
                       -Metric 20 -VserverContext "$SVM_NAME" `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        }

        #DataStoreLif for iSCSI and NFS
        #This LIF also is used for Sharing the vdbench files to all VMs for iSCSI/NFS and FCP. 
        New-NcNetInterface -Name $Global:config.VMsLIF.lif0.Name `
                           -Vserver "$SVM_NAME" -Role data -Node $Nodes[0].Node `
                           -Port $Global:config.VMsLIF.lif0.Port -DataProtocols nfs `
                           -Address $Global:config.VMsLIF.lif0.IP `
                           -Netmask $Global:config.VMsLIF.lif0.Netmask `
                           -FirewallPolicy data -AdministrativeStatus up `
                           -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        #Creating FCP LIF
        if($SVM_Prefix -eq "FCP"){
          # Create the Lifs
          # Get the Nodes of the HA
          $Nodes = Get-NcNode -ErrorVariable +Err -ErrorAction SilentlyContinue
          #DataStoreLif for FCP
          New-NcNetInterface -Name $Global:config.VMsLIF.lif1.Name `
                   -Vserver "$SVM_NAME" -Role data -Node $Nodes[0].Node `
                   -Port $Global:config.VMsLIF.lif1.Port -DataProtocols fcp `
                   -AdministrativeStatus up `
                   -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        }

    #Adding Error to Log File
    if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function DataLifsSVM($SVM_Prefix) {

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

#Delete the Lifs in case the Script was run before. 
$CurrentLifs = Get-NcNetInterface -Vserver "$SVM_NAME" -Name "$SVM_NAME*"
if($CurrentLifs.Count -gt 0){
    Set-NcNetInterface -Name "$SVM_NAME*" -Vserver "$SVM_NAME" `
                       -AdministrativeStatus down -Confirm:$false `
                       -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
    Remove-NcNetInterface -Name "$SVM_NAME*" -Vserver "$SVM_NAME" -Confirm:$false `
                          -ErrorVariable +Err -ErrorAction SilentlyContinue ` | Out-Null
    Remove-NcNetRoute -Destination 0.0.0.0/0 -Gateway $Global:config.VMsLIF.lif0.Gateway `
                      -Metric 20 -VserverContext "$SVM_NAME" -Confirm:$false `
                      -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
}

# Create the Lifs
# Get the Nodes of the HA
$Nodes = Get-NcNode 
$CurrentRoute = Get-NcNetRoute -Vserver "$SVM_NAME"

if(!$CurrentRoute){
    New-NcNetRoute -Destination 0.0.0.0/0 -Gateway $Global:config.VMsLIF.lif0.Gateway  -Metric 20 -VserverContext "$SVM_NAME" | Out-Null
}
  
if($SVM_Prefix -eq "NFS"){
    #DataLifs NFS
    New-NcNetInterface -Name $Global:config.LIFSNFS.lif1.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[0].Node -Port $Global:config.LIFSNFS.lif1.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSNFS.lif1.IP `
                       -Netmask $Global:config.LIFSNFS.lif1.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSNFS.lif2.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[0].Node -Port $Global:config.LIFSNFS.lif2.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSNFS.lif2.IP `
                       -Netmask $Global:config.LIFSNFS.lif2.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSNFS.lif3.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[1].Node -Port $Global:config.LIFSNFS.lif3.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSNFS.lif3.IP `
                       -Netmask $Global:config.LIFSNFS.lif3.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSNFS.lif4.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[1].Node -Port $Global:config.LIFSNFS.lif4.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSNFS.lif4.IP `
                       -Netmask $Global:config.LIFSNFS.lif4.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    }elseif($SVM_Prefix -eq "iSCSI"){
    #Datalifs iSCSI
    New-NcNetInterface -Name $Global:config.LIFSiSCSI.lif5.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[0].Node -Port $Global:config.LIFSiSCSI.lif5.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSiSCSI.lif5.IP `
                       -Netmask $Global:config.LIFSiSCSI.lif5.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSiSCSI.lif6.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[0].Node -Port $Global:config.LIFSiSCSI.lif6.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSiSCSI.lif6.IP `
                       -Netmask $Global:config.LIFSiSCSI.lif6.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSiSCSI.lif7.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[1].Node -Port $Global:config.LIFSiSCSI.lif7.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSiSCSI.lif7.IP `
                       -Netmask $Global:config.LIFSiSCSI.lif7.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSiSCSI.lif8.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[1].Node -Port $Global:config.LIFSiSCSI.lif8.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -Address $Global:config.LIFSiSCSI.lif8.IP `
                       -Netmask $Global:config.LIFSiSCSI.lif8.Netmask -FirewallPolicy data -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    Add-NciSCSIService -VserverContext "$SVM_NAME" -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    }elseif($SVM_Prefix -eq "FCP"){
    #Datalifs FCP
    New-NcNetInterface -Name $Global:config.LIFSFC.lif9.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[0].Node -Port $Global:config.LIFSFC.lif9.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -AdministrativeStatus up `
                       -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSFC.lif10.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[0].Node -Port $Global:config.LIFSFC.lif10.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSFC.lif11.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[1].Node -Port $Global:config.LIFSFC.lif11.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    New-NcNetInterface -Name $Global:config.LIFSFC.lif12.Name -Vserver "$SVM_NAME" `
                       -Role data -Node $Nodes[1].Node -Port $Global:config.LIFSFC.lif12.Port `
                       -DataProtocols $SVM_Prefix.ToLower() -AdministrativeStatus up `
                       -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    Add-NcFcpService -VserverContext "$SVM_NAME" -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    }
  Add-NcNfsService -VserverContext "$SVM_NAME" -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
  #Adding Error to Log File $Err or $Error
  if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
  
}
 
Function Mount-iSCSI-FCP-Datastore2($SVM_Prefix){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "NFS")){
    $DataStoreName = $Global:config.VMsLIF.lif0.Name
}elseif($SVM_Prefix -eq "FCP"){
$DataStoreName = $Global:config.VMsLIF.lif1.Name
}

    $SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix
    $LifStatus = Get-NcNetInterface -Vserver "$SVM_NAME" -InterfaceName $DataStoreName `
                                    -ErrorVariable Err -ErrorAction SilentlyContinue
    $LunID = [int]$Global:config.Other.LunID


    while($LifStatus.OpStatus -eq "down"){
    
        Write-Log "DATA LIFS are Operational down, Check $SVM_Prefix connectivity " -Path $LogFileName -Level Warn
        Read-Host "Press ENTER to check connectivity again....Otherwise type <Ctrl><C> if you want to exit the script"
        Write-Log "Press ENTER to check connectivity again....Otherwise type <Ctrl><C> if you want to exit the script" -Path $LogFileName -Level Warn  
        Write-Log "Checking $SVM_Prefix connectivity...." -Path $LogFileName -Level Info
        $LifStatus = Get-NcNetInterface -Vserver "$SVM_NAME" -InterfaceName $DataStoreName
    
    }

    if($LifStatus.OpStatus -eq "up"){

        do{

        $Global:DataAggr = Get-NcAggr | ?{ $_.AggrRaidAttributes.HasLocalRoot -eq $false }

        if($Global:DataAggr.Length -gt 2){

        Write-Log "There are more than 2 data aggregates, please select two...." -Path $LogFileName -Level Info
        $Global:DataAggr = $Global:DataAggr | Out-GridView -OutputMode Multiple -Title "Select two Data Aggregates"

        if(!($Global:DataAggr.Length -eq 2)){

        Write-Log "You have selected an incorrect number of data aggreggates, please select only TWO...." -Path $LogFileName -Level Warn 

        }
        }}while(!($Global:DataAggr.Length -eq 2))
        $DataAggr = $Global:DataAggr

        $AggrName = $DataAggr[0].Name
        $Path = '/vol/'+$DataStoreName+'/'+$DataStoreName
        #Calculating the size of the Datastore based on the number of VMs needed.
        $NumberVMperhost = $Global:config.Other.NumberVMperhost
        $HostCount = $Global:config.Hosts.Count
        $Storagesize = 40*$NumberVMperhost*$HostCount
        $DatastoreSize = [string]$Storagesize+'GB'
        $StorageLunsize = $Storagesize*0.90
        $DatastoreLunSize = [string]$StorageLunsize+'GB'

        Write-Log "Creating $SVM_Prefix LUN $DataStoreName in aggregate $AggrName -Size $DatastoreSize" -Path $LogFileName -Level Info
        New-NcVol -Name $DataStoreName -Aggregate $AggrName -Size $DatastoreSize `
                  -JunctionPath $Null -State "online" -VserverContext "$SVM_NAME" `
                  -SnapshotPolicy 'none' -SnapshotReserve 0 `
                  -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        Get-NcVol -Name $DataStoreName -ErrorVariable +Err -ErrorAction SilentlyContinue | Set-NcVolOption -Key guarantee -Value none
        New-NcLun -Path $Path -Size $DatastoreLunSize -OsType 'vmware' -VserverContext $SVM_NAME -ThinProvisioningSupportEnabled `
                  -ErrorVariable +Err -ErrorAction SilentlyContinue| Out-Null

  
    if($SVM_Prefix -eq "iSCSI"){
      #Adding iSCSI Target on ESXi Servers
      $Protocol = "iscsi"
                 foreach($ESXiserver in $Global:config.Hosts.GetEnumerator()){
                        foreach($iSCSILIF in $Global:config.LIFSiSCSI.GetEnumerator()){
                                $iSCSITarget = Get-IScsiHbaTarget -Address $iSCSILIF.Value.IP `
                                                                   -ErrorVariable +Err -ErrorAction SilentlyContinue
                                if(!$iSCSITarget){
                                Write-Log "Adding iSCSI Target on ESXi Servers: " -Path $LogFileName -Level Info
                                Get-VMHost -Name $ESXiserver.Value.Name | Get-VMHostHba -Type iScsi -WarningAction SilentlyContinue | New-IScsiHbaTarget -Address $iSCSILIF.Value.IP -WarningAction silentlyContinue -ErrorAction SilentlyContinue | Out-Null
                                }      
                        }
                 }

  }elseif($SVM_Prefix -eq "FCP"){
        $Protocol = "fcp"
     }

  #Create the igroup
    New-NcIgroup -Name 'vdbench' -Protocol $Protocol -Type 'vmware' -VserverContext $SVM_NAME `
                 -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    Write-Log 'Creating igroup called vdbench ' -Path $LogFileName -Level Info
    Add-NcLunMap -Path $Path -InitiatorGroup 'vdbench' -Id $LunID -VserverContext $SVM_NAME `
                 -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
  #Adding IQN to the igroup named vdbench
      foreach ($ESXiHost in $Global:config.Hosts.GetEnumerator()) {
        $H = Get-VMhost $ESXiHost.Value.Name -ErrorVariable +Err -ErrorAction SilentlyContinue

        if($SVM_Prefix -eq "iSCSI"){
            Write-Log "Getting IQN for $H" -Path $LogFileName -Level Info
            $hostview = Get-View $H.id
            $storage = Get-View $hostview.ConfigManager.StorageSystem
            $IQN = $storage.StorageDeviceInfo.HostBusAdapter.iScsiName      
            Add-NcIgroupInitiator -Name 'vdbench' -Initiator $IQN -VserverContext $SVM_NAME `
                                  -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
        Write-Log "Adding IQN for $H to vdbench igroup" -Path $LogFileName -Level Info
        }elseif($SVM_Prefix -eq "FCP"){
                Write-Log "Getting WWN for $H" -Path $LogFileName -Level Info
                $WWN = Get-VMHostHBA -VMHost $H -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}}

                    foreach($WWn in $WWN){
                    Add-NcIgroupInitiator -Name 'vdbench' -Initiator $WWn.WWN -VserverContext $SVM_NAME `
                                          -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                    Write-Log "Adding WWN for $H to vdbench igroup" -Path $LogFileName -Level Info
                    }
        }
     }            

     do{

  #Scanning HBAs
        foreach($H in $Global:config.Hosts.GetEnumerator()){
 
                $HostName = $H.Value.Name
                Write-Log "Refreshing HBAs on ESXi Server: $HostName" -Path $LogFileName -Level Info
                Get-VMHostStorage -VMHost $HostName -Refresh -RescanAllHba | Out-Null
 
        }
                             
                
        #Creating iSCSI/FCP DataStore
        $LunIDString = $LunID.ToString() #Lun ID
        $H = $Global:config.Hosts.Host00.Name    
        $H = Get-VMhost $H -WarningAction SilentlyContinue
        Write-Log "Creating $SVM_Prefix Datastore for $H" -Path $LogFileName -Level Info
        $LunIDReport = Get-LunID | where {($_.ESX -eq $H) -and ($_.LUNID -eq $LunIDString)}
        if($LunIDReport){
        New-Datastore -VMHost $H -Name $DataStoreName -Path $LunIDReport.Device -VMFS -WarningAction SilentlyContinue | Out-Null
        }else{
        Write-Log "Re-scanning the HBAs again as it failed to find LUN with ID number $LunIDString ." -Path $LogFileName -Level Warn 
        Write-Log "Please check the network connectivity (type <Ctrl><C> if you want to exit the script)" -Path $LogFileName -Level Warn      
        }


     }while(!$LunIDReport)

  }Else{
  
        Write-Log "Deployment Failed as DATA LIFS are Operational down, Delete and De-Deploy the environment" -Path $LogFileName -Level Error
        Read-Host "Press ENTER to Exit...."
        Return "DATALIFSDOWN"
        Break
     }

     #Adding Error to Log File $Err or $Error
    if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
}
 
Function Get-LunID {

$report = Get-VMHost -State Connected | %{
    #Adding -V2 as per VMware suggestions in PowerCLI. 
    $esxcli = Get-EsxCli -VMHost $_ -V2
    foreach($Hostserver in $Global:config.Hosts.GetEnumerator()){
      
        if( $Hostserver.Value.Name -eq $esxcli.VMHost.Name ){
         $esxcli.storage.core.device.list.Invoke() |
         Select @{N='ESX';E={$esxcli.VMHost.Name}},Device,
            @{N='LUNID'; E={
            $d = $_
                    if(([Version]$esxcli.VMHost.Version).Major -lt 6){
                        $lun = Get-ScsiLun -VmHost $esxcli.VMhost | Where {$_.CanonicalName -eq $d.Device}
                        $runtime = $lun.RuntimeName
                    }
                    else{
                    $lun = $esxcli.VMHost.ExtensionData.Config.StorageDevice.ScsiLun | Where-Object{$_.CanonicalName -eq $d.Device}
                    $lunUuid = $lun.Uuid
                    $runtime = ($esxcli.VMHost.ExtensionData.Config.StorageDevice.MultipathInfo.Lun | Where-Object{$_.Id -eq $lunUuid}).Path[0].Name
                    $runtime = $runtime.Split(',')[0]
                    }
            $runtime.Split('L')[1]
            }}
        }
    }
}

return $report

}
 
Function Mount-NFSDatastore2($SVM_Prefix) {

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "NFS")){

$DataStoreName = $Global:config.VMsLIF.lif0.Name

}elseif($SVM_Prefix -eq "FCP"){

$DataStoreName = $Global:config.VMsLIF.lif1.Name

}
$LifStatus = Get-NcNetInterface -Vserver "$SVM_NAME" -InterfaceName $DataStoreName `
                                -ErrorVariable Err -ErrorAction SilentlyContinue

   while($LifStatus.OpStatus -eq "down"){
    
    Write-Log "DATA LIFS are Operational down, Check $SVM_Prefix connectivity, Otherwise type <Ctrl><C> if you want to exit the script" -Path $LogFileName -Level Warn
    Read-Host "Press ENTER to check connectivity again...."
    Write-Log "Press ENTER to check connectivity again...." -Path $LogFileName -Level Warn  
    Write-Log "Checking $SVM_Prefix connectivity...." -Path $LogFileName -Level Warn
    $LifStatus = Get-NcNetInterface -Vserver "$SVM_NAME" -InterfaceName $DataStoreName
    
    }


  if ($LifStatus.OpStatus -eq "up"){

        $NFSExportPolicy = Get-NcExportPolicy -Name "$SVM_NAME" -VserverContext "$SVM_NAME"
        if($NFSExportPolicy){
        
                $attr = Get-NcVol -Template
                Initialize-NcObjectProperty -Object $attr -Name VolumeExportAttributes | Out-Null
                $attr.VolumeExportAttributes.Policy = 'default'
                $query = Get-NcVol -Template
                $query.Name = "$DataStoreName"
                $query.Vserver = "$SVM_NAME"
                Update-NcVol -Query $query -Attributes $attr -FlexGroupVolume:$false | Out-Null
                Remove-NcExportPolicy -Name "$SVM_NAME" -VserverContext "$SVM_NAME" -Confirm:$false | Out-Null
                $query.Name = "vdbench_root"
                Update-NcVol -Query $query -Attributes $attr -FlexGroupVolume:$false | Out-Null
                Remove-NcExportPolicy -Name "$SVM_NAME" -VserverContext "$SVM_NAME" -Confirm:$false | Out-Null
                
        }else{

        New-NcExportPolicy -Name "$SVM_NAME" -VserverContext "$SVM_NAME" `
                           -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null

        }

        do{

        $Global:DataAggr = Get-NcAggr | ?{ $_.AggrRaidAttributes.HasLocalRoot -eq $false }

        if($Global:DataAggr.Length -gt 2){

        Write-Log "There are more than 2 data aggregates, please select two...." -Path $LogFileName -Level Info
        $Global:DataAggr = $Global:DataAggr | Out-GridView -OutputMode Multiple -Title "Select two Data Aggregates"

        if(!($Global:DataAggr.Length -eq 2)){

        Write-Log "You have selected an incorrect number of data aggreggates, please select only TWO...." -Path $LogFileName -Level Warn 

        }
        }}while(!($Global:DataAggr.Length -eq 2))

        $DataAggr = $Global:DataAggr


        $vdbenchVol = Get-NcVol -Name $DataStoreName -Vserver "$SVM_NAME"

                if ($vdbenchVol){
                    Write-Log "$DataStoreName already exist, please delete and redeploy the environment and start again : " -Path $LogFileName -Level Error
                    Read-Host "Press ENTER to Exit...."
                    Return "DATALIFSDOWN"
                    Break
                }else{
                
                    #This is to change the policy on the root volume so that we can map the NFS volume on VCenter
                    $attr = Get-NcVol -Template
                    Initialize-NcObjectProperty -Object $attr -Name VolumeExportAttributes | Out-Null
                    $attr.VolumeExportAttributes.Policy = "$SVM_NAME"
                    $query = Get-NcVol -Template
                    $query.Name = "vdbench_root"
                    $query.Vserver = "$SVM_NAME"
                    Update-NcVol -Query $query -Attributes $attr -FlexGroupVolume:$false `
                                 -ErrorVariable +Err -ErrorAction SilentlyContinue| Out-Null
                    #
                    $JunctionPath = "/"+$DataStoreName
                    #Calculating the size of the Datastore based on the number of VMs needed. 
                    $NumberVMperhost = $Global:config.Other.NumberVMperhost
                    $HostCount = $Global:config.Hosts.Count
                    $Storagesize = 20*$NumberVMperhost*$HostCount
                    $DatastoreSize = [string]$Storagesize+'GB'

                    New-NcVol -Name $DataStoreName -Aggregate $DataAggr[0].Name -Size $DatastoreSize `
                              -JunctionPath $JunctionPath -ExportPolicy "$SVM_NAME" -SecurityStyle "Unix" `
                              -UnixPermissions "0777" -State "online" -VserverContext "$SVM_NAME" `
                              -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                    Get-NcVol -Name $DataStoreName | Set-NcVolOption -Key guarantee -Value none        
                        
                        #Creating the Export NFS rules for the ESXi Servers
                        ForEach($item in $Global:config.Hosts.GetEnumerator()){
                            
                            $VMHostName = $item.Value.Name

                            if($Global:config.other.DSwitch){
                                #if DSwitch is selected in the Vmware Enviroment
                                $IPInfo = Get-VDPortGroup -Name $Global:config.Other.NetworkName | Get-VMHostNetworkAdapter -VMhost $VMHostName -WarningAction silentlyContinue
                            }else{
                                #if vSwitch is selected in the Vmware Enviroment
                                $PortGroupName = $Global:config.other.PortGroupName
                                $IPInfo = Get-VMHostNetworkAdapter -VMKernel -VMHost $VMHostName | ? {$_.PortgroupName -eq $PortGroupName} | select Name,VMhost,IP   
                            }
                                
                             #If VMkernel is not in the same PortGroup $IPInfo is going to be empty.
                                if($IPInfo){
                                    New-NcExportRule -Policy "$SVM_NAME" -ClientMatch $IPInfo.IP `
                                                     -ReadOnlySecurityFlavor any -ReadWriteSecurityFlavor any `
                                                     -VserverContext "$SVM_NAME" -Protocol nfs -SuperUserSecurityFlavor any `
                                                     -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                }else{
                                    
                                    New-NcExportRule -Policy "$SVM_NAME" -ClientMatch "0.0.0.0/0" `
                                                     -ReadOnlySecurityFlavor any -ReadWriteSecurityFlavor any `
                                                     -VserverContext "$SVM_NAME" -Protocol nfs -SuperUserSecurityFlavor any `
                                                     -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                    Write-Log -Message "NFS export is 0.0.0.0/0 since suitable VMkernels were not found." -Path $LogFileName -Level Warn        
                                }
                                $NFSPath = "/"+$DataStoreName
                                New-Datastore -Nfs -VMHost $VMHostName -Name $DataStoreName -Path $NFSPath `
                                              -NfsHost $LifStatus.Address -WarningAction silentlyContinue `
                                              -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null

                        }
                
                }
        
     }else{
   
        Write-Log "Deployment Failed as DATA LIFS are Operational down, Delete and De-Deploy the environment" -Path $LogFileName -Level Error
        Read-Host "Press ENTER to Exit...."
        Return "DATALIFSDOWN"
        Break
   }

#Adding Error to Log File $Err or $Error
if($Error.Count -gt 0) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Get-FileName($initialDirectory, [string]$ExtentionFile){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "Select a $ExtentionFile file"
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "$ExtentionFile (*.$ExtentionFile)| *.$ExtentionFile"
    $OpenFileDialog.ShowDialog() | Out-Null
    #$show = $OpenFileDialog.ShowDialog()
    #This returns the Path of the config File to be imported 
    $OpenFileDialog.FileName
    
    $ConfigFile = $OpenFileDialog.FileName    
    #Extracting the name of the configuration file path
    $ConfigFileName = $ConfigFile.Split('\')[-1].split('.')[0]
    #Adding the .log extention
    $LogFileName = $ConfigFileName+'_LogFile.log'
    #This Returns the Log File Name 
    $LogFileName
    
    #This returns [Null]
    $LogFilePath = ""
    $LogFilePath
    

}
 
Function Import-OVA2($CurrentPath, $SVM_Prefix){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$vdbenchtemplate = Get-Template -Name vdbench-template -ErrorVariable Err -ErrorAction SilentlyContinue

if(-not $vdbenchtemplate){

if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "NFS")){

$DataStoreName = $Global:config.VMsLIF.lif0.Name

}elseif($SVM_Prefix -eq "FCP"){

$DataStoreName = $Global:config.VMsLIF.lif1.Name

}

$ESXiHost = $Global:config.Hosts.Host00.Name

#OVA Path File.... 
$inputova = $Global:config.Other.PathOVA

do{

if (!(Test-Path $inputova)) {

    Write-Log "$inputova absent in the Path.... " -Path $LogFileName -Level Warn
    Write-Log "Please select the path to import the OVA.... " -Path $LogFileName -Level Warn
    $inputOVA_Array = Get-FileName $CurrentPath "ova"
    # $inputova is an array
    # $inputova[0] is the Configuratiton path.
    $inputova = $inputOVA_Array[0]
                    
}
        #$inputova = Get-FileName $CurrentPath "ova" 
        Write-Log "Please find below the OVA file selected:" -Path $LogFileName -Level Info
        Write-Log "$inputova" -Path $LogFileName -Level Info
        #$Import_option = Read-Host "Type 'C' to Continue Importing the OVA......  "
        $Import_option = 'C'
                       if ($Import_option -eq 'C'){
                        #Import the OVA                                                         
                              if(-not (VSwitch-Check $ESXiHost)){
                                    #Create the VSwitch.... 
                                    $VSwitch = Get-VirtualSwitch -VMHost $ESXiHost -Standard
                                        if(-not $VSwitch){
                                            Write-Log "Creating a VSwitch to import OVA......" -Path $LogFileName -Level Info
                                            New-VirtualSwitch -VMHost $ESXiHost -Name vdbench `
                                                              -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                        }
                                    Write-Log "Creating a Port Group to import OVA......" -Path $LogFileName -Level Info
                                    $VSwitch = Get-VirtualSwitch -VMHost $ESXiHost -Standard
                                    New-VirtualPortGroup -VirtualSwitch $VSwitch  -Name "VM Network" `
                                                         -ErrorVariable +Err -ErrorAction SilentlyContinue| Out-Null    
                                }
                                 $ESXiHostInfo = Get-VMHost $ESXiHost 
                                 Import-vApp -Source $inputova -Name vdbench-template -VMHost $ESXiHostInfo -Datastore $DataStoreName -force `
                                             -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                 $template = Get-VM vdbench-template | Set-VM -ToTemplate -Name vdbench-template -Confirm:$false `
                                                                              -ErrorVariable +Err -ErrorAction SilentlyContinue
                                                if($template -ne $null){
                                                    Write-Log "vdbench-template has been successfully created...." -Path $LogFileName -Level Info
                                                }else{
                                                Write-Log "Deployment Failed as vdbench-template was not successfully created" -Path $LogFileName -Level Error
                                                Read-Host "Press ENTER to check to try import again....Otherwise type <Ctrl><C> if you want to exit the script"
                                                Write-Log "Press ENTER to check to try import again....Otherwise type <Ctrl><C> if you want to exit the script" -Path $LogFileName -Level Info
                                                
                                                }
                            }
       }while($template -eq $null)
       
                     
     }else{
     Write-Log "vdbench-template has been already imported....  " -Path $LogFileName -Level Info
     }
#Adding Error to Log File $Err or $Error
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Create-NFSVol2{

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_NAME = $Global:config.SVM.Name+"_NFS"
$Count = 0
do{

$VMWorkers = Get-VM -Name "$SVM_NAME*" -ErrorVariable Err -ErrorAction SilentlyContinue |  ?{$_.PowerState -eq "PoweredOn"} 
                    

$NumberWorkers = $Global:config.VMs.Count

Write-Log "Checking that all $NumberWorkers workers are Powered ON.." -Path $LogFileName -Level Info

Start-Sleep 5

if($Count -eq 5){
Write-Log "Make sure that all $NumberWorkers workers are Powered ON " -Path $LogFileName -Level Warn
Write-Log "Or make sure the number of VMs per host is Correct " -Path $LogFileName -Level Warn
$ExitEntry = Read-Host "Otherwise, type 'exit' to stop the script to delete and re-deploy...(To Continue Type any key)"
        if($ExitEntry -eq "exit") {
        return "IssuesWithVMs"
        break
        }
$Count = 0
}

$Count++

}while(!($VMWorkers.Length -eq $NumberWorkers))

Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log "                   Creation of NFS Volumes                " -Path $LogFileName -Level Info
Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
#Converting string to Int32
$strNumberofVolumesPerVM = $Global:config.Other.NumberofVolumesPerVM
$BooleanValue = $strNumberofVolumesPerVM -match "^[0-9]{1,4}"
$HasValue = $Matches
$StrValue = $HasValue.Values
[int]$NumberofVolumesPerVM = [convert]::ToInt32($StrValue, 10)
$DataAggr = $Global:DataAggr

    Write-Log "$NumberofVolumesPerVM $SVM_Prefix Volumes per VM will be created, and the distribution " -Path $LogFileName -Level Info
    Write-Log "will be acrossed TWO Data Aggregates " -Path $LogFileName -Level Info
    Write-Log "Number of vdbench VMs " $Global:config.VMs.Count -Path $LogFileName -Level Info
    $NumberofVolumesPerVM = $Global:config.Other.NumberofVolumesPerVM
    $VolumeSize = $Global:config.Other.VolumeSize
    $VMCount = $Global:config.VMs.Count
    $numberVOLS = $VMCount*$NumberofVolumesPerVM
    Write-Log "Total number of NFS Vols: " $numberVOLS -Path $LogFileName -Level Info
            
            do{
            $Continue_NFSVOLS = read-host "Please press 'c' to continue, type 'exit' to return to the main menu... "
            if($Continue_NFSVOLS -eq "c"){
                       #Big for loop for each Host
                       ForEach($item in $Global:config.VMs.GetEnumerator()){
                       #Loop for Each Aggregate
                                for($aggregate = 0 ; $aggregate -lt $DataAggr.Length ; $aggregate++){
        
                                                for($Volume = 1 ; $Volume -le $NumberofVolumesPerVM ; $Volume++){
                                                 #Loop for aggregate
                                                            if($Volume -gt $NumberofVolumesPerVM/2){
                                                                     if($aggregate -eq ($DataAggr.Length-1) ){
                                                                     
                                                                     }else{
                                                                      $aggregate++
                                                                     }
                                                              }
                                                 $VolumeName = $item.Value.Name+"_NFS_VD_vol_"+$Volume
                                                 $JunctionPath = "/"+$VolumeName
                                                 $AggrName = $DataAggr[$aggregate].Name
                                                 Write-Log "Creating Volume $VolumeName in aggregate $AggrName -Size $VolumeSize" -Path $LogFileName -Level Info
                                                 New-NcVol -Name $VolumeName -Aggregate $DataAggr[$aggregate].Name -Size $VolumeSize `
                                                           -JunctionPath $JunctionPath -ExportPolicy $item.Value.Name -SecurityStyle "Unix" `
                                                           -UnixPermissions "0777" -State "online" -VserverContext "$SVM_NAME" -SnapshotPolicy 'none' `
                                                           -SnapshotReserve 0 `
                                                           -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                                  
                                                 }
                                     }
                        }
             }elseif($Continue_NFSVOLS -eq "exit"){
                 Write-Log "You can delete what was deployed up to this point by choosing " -Path $LogFileName -Level Warn
                 Write-Log "the Delete option from the main Menu and selecting the config file. " -Path $LogFileName -Level Warn
                 Return "CancelNFSVols"
                 Break
             }else{
                Write-Log "Incorrect option selected, please enter 'c' to continue or 'exit' to return to the main menu..."  -Path $LogFileName -Level Warn
             }
             }While(!(($Continue_NFSVOLS -eq "c") -or ($Continue_NFSVOLS -eq "exit") ))

#Adding Error to Log File $Err or $Error
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
}
 
Function Create-iSCSI-FC-Lun2($SVM_Prefix){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix
$LunID = [int]$Global:config.Other.LunID
$Count = 0

Write-Log "Checking that all $NumberWorkers workers are Powered ON.."  -Path $LogFileName -Level Info

do{

$VMWorkers = Get-VM -Name "$SVM_NAME*" -ErrorVariable Err -ErrorAction SilentlyContinue |  ?{$_.PowerState -eq "PoweredOn"}

$NumberWorkers = $Global:config.VMs.Count
Start-Sleep 1

if($Count -eq 10){

Write-Log "Make sure that all $NumberWorkers workers are Powered ON "  -Path $LogFileName -Level Warn
Write-Log "Or make sure the number of VMs per host is Correct "  -Path $LogFileName -Level Warn
$ExitEntry = Read-Host "Otherwise, type 'exit' to stop the script to delete and re-deploy...(To Continue Type any key)"
if($ExitEntry -eq "exit") {
return "IssuesWithVMs"
break

}
$Count = 0
}

$Count++

}while(!($VMWorkers.Length -eq $NumberWorkers))


Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log "               Creation of $SVM_Prefix LUNs               " -Path $LogFileName -Level Info
Write-Log "==========================================================" -Path $LogFileName -Level Info
Write-Log " " -Path $LogFileName -Level Info
#Converting string to Int32
$strNumberofVolumesPerVM = $Global:config.Other.NumberofVolumesPerVM
$BooleanValue = $strNumberofVolumesPerVM -match "^[0-9]{1,4}"
$HasValue = $Matches
$StrValue = $HasValue.Values
[int]$NumberofVolumesPerVM = [convert]::ToInt32($StrValue, 10)

$DataAggr = $Global:DataAggr

    Write-Log "$NumberofVolumesPerVM $SVM_Prefix LUNs per VM will be created, and the distribution " -Path $LogFileName -Level Info
    Write-Log "will be acrossed TWO Data Aggregates " -Path $LogFileName -Level Info
    Write-Log "Number of vdbench VMs " $Global:config.VMs.Count -Path $LogFileName -Level Info
    
    $VolumeSize = $Global:config.Other.VolumeSize
    $BooleanValue = $VolumeSize -match "^[0-9]{1,4}"
    $HasValue = $Matches
    $StrValue = $HasValue.Values
    [int]$IntValue = [convert]::ToInt32($StrValue, 10)
    $FlexVolSize = $IntValue*1.2 
    $LunVolSize = $IntValue
    $LunVolSize = [string]$LunVolSize+'GB'
    $FlexVolSize = [string]$FlexVolSize+'GB'
    $VMCount = $Global:config.VMs.Count
    $numberVOLS = $VMCount*$NumberofVolumesPerVM
    Write-Log "Total number of $SVM_Prefix LUNs: " $numberVOLS -Path $LogFileName -Level Info
            
            do{
            $Continue_LUNsVOLS = read-host "Please press 'c' to continue, type 'exit' to return to the main menu... "
            if($Continue_LUNsVOLS -eq 'c'){
                       #Big for loop for each Host
                       $LunID = $LunID + 1
                       ForEach($item in $Global:config.VMs.GetEnumerator()){
                       #Loop for Each Aggregate
                                for($aggregate = 0 ; $aggregate -lt $DataAggr.Length ; $aggregate++){
        
                                                for($Volume = 1 ; $Volume -le $NumberofVolumesPerVM ; $Volume++){
                                                 #Loop for aggregate
                                                            if($Volume -gt $NumberofVolumesPerVM/2){
                                                                     if($aggregate -eq ($DataAggr.Length-1) ){
                                                                     
                                                                     }else{
                                                                      $aggregate++
                                                                     }
                                                              }
                                                 $VolumeName = $item.Value.Name+"_"+$SVM_Prefix+"_VD_vol_"+$Volume
                                                 $Path = '/vol/'+$VolumeName+'/'+$VolumeName
                                                 $JunctionPath = $null
                                                 $AggrName = $DataAggr[$aggregate].Name
                                                 Write-Log "Creating $SVM_Prefix LUN $VolumeName in aggregate $AggrName -Size $VolumeSize" -Path $LogFileName -Level Info
                                                 New-NcVol -Name $VolumeName -Aggregate $DataAggr[$aggregate].Name -Size $FlexVolSize `
                                                           -JunctionPath $JunctionPath -State "online" -VserverContext "$SVM_NAME" `
                                                           -SnapshotPolicy 'none' -SnapshotReserve 0 `
                                                           -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                                 New-NcLun -Path $Path -Size $LunVolSize -OsType 'linux' -VserverContext $SVM_NAME `
                                                           -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                                 Add-NcLunMap -Path $Path -InitiatorGroup 'vdbench' -Id $LunID -VserverContext $SVM_NAME `
                                                              -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                                 $LunID++


                                                 }
                                }
                       }
              }elseif($Continue_LUNsVOLS -eq "exit"){
              Write-Log "You can delete what was deployed up to this point by choosing "  -Path $LogFileName -Level Warn
              Write-Log "the Delete option from the main Menu and selecting the config file. " -Path $LogFileName -Level Warn
              Return "CancelLunsVols"
              Break
             }else{

              Write-Log "Incorrect option selected, please enter 'c' to continue or 'exit' to return to the main menu..."  -Path $LogFileName -Level Warn
             
             }
             }While(!(($Continue_LUNsVOLS -eq "c") -or ($Continue_LUNsVOLS -eq "exit") ))
   
foreach($H in $Global:config.Hosts.GetEnumerator()){
 
$HostName = $H.Value.Name
Write-Log "Refreshing HBAs on ESXi Server: $HostName" -Path $LogFileName -Level Info
Get-VMHostStorage -VMHost $HostName -Refresh -RescanAllHba | Out-Null
 
 }

#Adding Error to Log File $Err or $Error
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

 }
 
Function Create-RDMLun2{

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$LunIDReport = Get-LunID
$LunID = [int]$Global:config.Other.LunID
$LunID = $LunID + 1

<#
foreach($vdbenchVMs in $Global:config.VMs.GetEnumerator()){
    #Shutting down VMs...
    $VM = $vdbenchVMs.Value.Name
    $VMObject = Get-VM $VM -ErrorVariable +Err -ErrorAction SilentlyContinue 
    
    if($VMObject.Guest.State -eq "Running"){
    
    Write-Log "Shuting down $VM to add RMDs and SCSI Controllers....." -Path $LogFileName -Level Info
    Shutdown-VMGuest -VM $VMObject -Confirm:$false -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
    
    }else{ 
    
    Write-Log "Stopping $VM to add RMDs and SCSI Controllers....." -Path $LogFileName -Level Info
    Stop-VM -VM $VMObject -Confirm:$false -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
   
    }

}

Start-Sleep 60
#>

foreach($vdbenchVMs in $Global:config.VMs.GetEnumerator()){

    $VM = $vdbenchVMs.Value.Name
    $VMObject = Get-VM $VM 
    #Number of volumes per VM
    #Converting string to Int32
    $strNumberofVolumesPerVM = $Global:config.Other.NumberofVolumesPerVM
    $BooleanValue = $strNumberofVolumesPerVM -match "^[0-9]{1,4}"
    $HasValue = $Matches
    $StrValue = $HasValue.Values
    [int]$NumberofVolumesPerVM = [convert]::ToInt32($StrValue, 10)

    for($i=0; $i -lt $NumberofVolumesPerVM ; $i++){
    
        $HostServer = $Global:config.Hosts.Host00.Name
        $LunString = $LunID.ToString()
        $LunInfo = $LunIDReport | where {($_.ESX -eq $HostServer) -and $_.LUNID -eq $LunString}
        $DeviceName = "/vmfs/devices/disks/"+$LunInfo.Device
        New-HardDisk -VM $VMObject -DiskType RawPhysical -DeviceName $DeviceName `
                     -Controller "SCSI controller 0" -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
        Write-Log "Creating RDM in $VM with LUN ID $LunID ....." -Path $LogFileName -Level Info
        $LunID++
    }

}


foreach($vdbenchVMs in $Global:config.VMs.GetEnumerator()){
    #ReStarting VMs...
    $VM = $vdbenchVMs.Value.Name
    $VMObject = Get-VM $VM -ErrorVariable +Err -ErrorAction SilentlyContinue 
    Write-Log "Starting $VM....." -Path $LogFileName -Level Info 
    Restart-VM -VM $VMObject -Confirm:$false -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
}

Start-Sleep 60

foreach($vdbenchVMs in $Global:config.VMs.GetEnumerator()){
    #Checking Connectivity...
    $VM = $vdbenchVMs.Value.IP
    $VMName = $vdbenchVMs.Value.Name
    Write-Log "Testing Connectivity in $VMName....." -Path $LogFileName -Level Info
    while(!(Test-Connection -ComputerName $VM -Count 1  -ErrorAction SilentlyContinue )){
    Write-Log "Failed Connectivity test in $VMName, Trying again....." -Path $LogFileName -Level Info 
    Start-Sleep 15

    }
}

#Adding Error to Log File $Err or $Error
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Import-Specsvdbench2($SVM_Prefix) {

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

#Delete the profiles in case the Script was run before. 
$CurrentOSSpecs = Get-OSCustomizationSpec -Name "$SVM_NAME*"

if($CurrentOSSpecs.Count -gt 0){

Remove-OSCustomizationSpec -OSCustomizationSpec "$SVM_NAME*" -Confirm:$false | Out-Null

}

ForEach($item in $Global:config.VMs.GetEnumerator() | Sort Key){

$NewSpec = New-OSCustomizationSpec –Name $item.Value.Name –Domain vdbench –DnsServer "8.8.8.8" –NamingScheme VM –OSType Linux
Get-OSCustomizationSpec $item.Value.Name | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp `
                                                                                                         -IpAddress $item.Value.IP `
                                                                                                         -SubnetMask $Global:config.VMs.VM00.Netmask `
                                                                                                         -DefaultGateway $Global:config.VMs.VM00.Gateway `
                                                                                                         -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
}
#Clear-Host

Write-Log "Please find below the specs of all VMs " -Path $LogFileName -Level Info
$OScustomizationSpec = Get-OSCustomizationSpec -Name "$SVM_NAME*" | Get-OSCustomizationNicMapping
Write-Log -Message "Spec               DefaultGateway  IPAddress " -Path $LogFileName -Level Info 
Write-Log -Message "----               --------------  --------- " -Path $LogFileName -Level Info
$OScustomizationSpec | %{ Write-Log -Message $_.Spec.Name -Message2 $_.IPAddress -Message3 $_.DefaultGateway -Path $LogFileName -Level Info}

#Adding Error to Log File $Err or $Error
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Create-VMsvdbench2($SVM_Prefix) {

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]
        
$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "NFS")){

$DataStoreName = $Global:config.VMsLIF.lif0.Name

}elseif($SVM_Prefix -eq "FCP"){

$DataStoreName = $Global:config.VMsLIF.lif1.Name

}


# Only Refresh the HBA when it is an iSCSI deployment....
if($SVM_Prefix -eq "iSCSI" -or $SVM_Prefix -eq "FCP"){
        #Scanning HBAs
        foreach($H in $Global:config.Hosts.GetEnumerator()){
 
                $HostName = $H.Value.Name
                Write-Log "Refreshing HBAs on ESXi Server: $HostName" -Path $LogFileName -Level Info
                Get-VMHostStorage -VMHost $HostName -Refresh -RescanAllHba -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null
               
        }
}

# Only Refresh the HBA when it is an FCP deployment....
if($SVM_Prefix -eq "FCP"){
        #Scanning HBAs
        foreach($H in $Global:config.Hosts.GetEnumerator()){
 
                $HostName = $H.Value.Name
                Write-Log "Refreshing HBAs on ESXi Server: $HostName" -Path $LogFileName -Level Info
                Get-VMHostStorage -VMHost $HostName -Refresh -RescanAllHba -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                
        }
}


     $spec = Get-OSCustomizationSpec -Name "$SVM_NAME*"
     $StartLocation = 0
     $numberVMperhost = $Global:config.Other.NumberVMperhost
     $numberVMperhost1 = $numberVMperhost
     ForEach($item in $Global:config.Hosts.GetEnumerator() | Sort Key){
            
             for($Location = $StartLocation ; $Location -lt $numberVMperhost1 ; $Location++){
                        
                    $VMHOSTName = $item.Value.Name
                    $specName = $spec[$Location].Name
                    $ESXiHost = Get-VMHost -Name $VMHOSTName
                    $DataStoreOnline = Get-VMHost -Name $VMHOSTName | Get-Datastore -Name $DataStoreName -Refresh `
                                                                                    -WarningAction SilentlyContinue `
                                                                                    -ErrorAction SilentlyContinue `
                                                                                    -ErrorVariable +Err
                        #Initialization of the Refresh counter
                        $RefreshCount = 0
                        while(!($DataStoreOnline.State -eq "Available")){
                                Write-Log "Refreshing HBAs again on ESXi Server: $VMHOSTName as Datastore $DataStoreName cannot be found..." -Path $LogFileName -Level Warn
                                Get-VMHostStorage -VMHost $VMHOSTName -Refresh -RescanAllHba | Out-Null
                                $DataStoreOnline = Get-VMHost -Name $VMHOSTName | Get-Datastore -Name $DataStoreName `
                                                                                                -WarningAction SilentlyContinue `
                                                                                                -ErrorAction SilentlyContinue `
                                                                                                -ErrorVariable +Err
                                   if($RefreshCount -eq 20){
                                       Write-Log "Make sure that $DataStoreName is available for $VMHOSTName ESXi Server:"  -Path $LogFileName -Level Warn
                                       $ExitEntry = Read-Host "If you want to keep refreshing the HBAs type any key, Otherwise type 'exit' to stop the script (To Continue Type any key)"
                                        if($ExitEntry -eq "exit"){
                                            return "DatastoreCannotbeFound"
                                            Write-Log "$VMHOSTName ESXi server couldnt find Datastore $DataStoreName..." -Path $LogFileName -Level Error
                                            break
                                        }

                                       $RefreshCount = 0
                                   } 
                                   $RefreshCount++
                                }
                               
                               Write-Log "Cloning VM $specName on ESXI server $VMHOSTName ......." -Path $LogFileName -Level Info
                               New-VM -VMhost $VMHOSTName -Name $specName -Template vdbench-template `
                                      -OSCustomizationSpec $specName -Datastore $DataStoreName `
                                      -DrsAutomationLevel Manual -WarningAction silentlyContinue `
                                      -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                                
                        #if this is a vswitch or dswitch.
                        if($Global:config.other.DSwitch){
                        #dswitch
                        $PortGroupname = $Global:config.Other.NetworkName                        
                        }else{
                        #vswitch
                        #It has been changed to -Portgroup as per VMware-PowerCLI warnings.
                        $PortGroupname = $Global:config.Other.PortGroupName
                        }
                        $VMNetwork = Get-VirtualPortGroup -Name $PortGroupname -VMHost $ESXiHost `
                                                          -ErrorVariable +Err -ErrorAction SilentlyContinue 
                        Get-VM $specName | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $VMNetwork -Confirm:$false `
                                                                                   -ErrorVariable +Err -ErrorAction SilentlyContinue | Out-Null
                                      
                        }
             $StartLocation = $Location
             $numberVMperhost1 = $numberVMperhost1 + $numberVMperhost
            }
            Write-Log "Starting all VMs......." -Path $LogFileName -Level Info          
            Start-VM -VM "$SVM_NAME*" -Confirm:$false `
                     -ErrorVariable Err -ErrorAction SilentlyContinue | Out-Null

#Adding Error to Log File $Err or $Error
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Mounting-NFSVolumes2($VMName){
 
# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

 #Creating the Folders at /mnt/vdbenchTest*

 $SVM_NAME = $Global:config.SVM.Name+"_NFS"

 $DataAggr = $Global:DataAggr
 $NFSVolumes1 = Get-NcVol -Vserver $SVM_NAME -Name "$VMName*" -Aggregate $DataAggr[0]
 $NFSVolumes2 = Get-NcVol -Vserver $SVM_NAME -Name "$VMName*" -Aggregate $DataAggr[1]
 
 $NFSLIF1 = $Global:config.LIFSNFS.lif1.IP
 $NFSLIF2 = $Global:config.LIFSNFS.lif2.IP

 $NFSLIF3 = $Global:config.LIFSNFS.lif3.IP
 $NFSLIF4 = $Global:config.LIFSNFS.lif4.IP

 $Location = 0
 foreach($NFSvol in $NFSVolumes1.Name){
 $Location++
        if($Location -eq 1){
        $DATALIF = $NFSLIF1
        }elseif($Location -eq 2){
        $DATALIF = $NFSLIF2
        $Location = 0
        }
        $PermanentMount = "echo '$DATALIF`:/$NFSvol /mnt/$NFSvol nfs defaults        0 0' >> /etc/fstab"
        $Mount = "mount -t nfs $DATALIF`:/$NFSvol /mnt/$NFSvol"
        $Folder = "mkdir /mnt/$NFSvol"
        #1. Creating the Folders Command
        Invoke-SSHCommand -Index 0 -Command $Folder | Out-Null
        #2. adding the Permanent NFS mounting point
        Invoke-SSHCommand -Index 0 -Command $PermanentMount | Out-Null
        #3. Mounting the NFS vol
        Invoke-SSHCommand -Index 0 -Command $Mount | Out-Null
 }

 $Location = 0
 foreach($NFSVol in $NFSVolumes2){
      $Location++
        if($Location -eq 1){
            $DATALIF = $NFSLIF3
        }elseif($Location -eq 2){
            $DATALIF = $NFSLIF4
            $Location = 0
        }
        $PermanentMount = "echo '$DATALIF`:/$NFSvol /mnt/$NFSvol nfs defaults        0 0' >> /etc/fstab"
        $Mount = "mount -t nfs $DATALIF`:/$NFSvol /mnt/$NFSvol"
        $Folder = "mkdir /mnt/$NFSvol"
        #1. Creating the Folders Command
        Invoke-SSHCommand -Index 0 -Command $Folder | Out-Null
        #2. adding the Permanent NFS mounting point
        Invoke-SSHCommand -Index 0 -Command $PermanentMount | Out-Null
        #3. Mounting the NFS vol
        Invoke-SSHCommand -Index 0 -Command $Mount | Out-Null
 }
 
#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }  
         
 }
 
Function Adding-DNS2{
# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

            ForEach($item in $Global:config.VMs.GetEnumerator() | Sort Key){
                $IP = $item.Value.IP
                $VMName = $item.Value.Name
                $DNSLINE = "echo '$IP $VMName' >> /etc/hosts"
                $StartNTPServices = "systemctl start ntpd"
                $EnableNTPServices = "systemctl enable ntpd"
                Invoke-SSHCommand -Index 0 -Command $DNSLINE | Out-Null
                Invoke-SSHCommand -Index 0 -Command $StartNTPServices | Out-Null
                Invoke-SSHCommand -Index 0 -Command $EnableNTPServices | Out-Null
            }

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
 }
 
Function Config-DNSVM2($SVM_Prefix){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$secpasswd = ConvertTo-SecureString "Netapp1!" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("root", $secpasswd)

if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "FCP")){
Start-Sleep 60
}elseif($SVM_Prefix -eq "NFS"){
Start-Sleep 45
}

 ForEach($item in $Global:config.VMs.GetEnumerator()){
                    
                  if (Test-Connection -ComputerName $item.Value.IP -Quiet) {

                          $SSHSesionVM = New-SSHSession -ComputerName $item.Value.IP -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120
                          $IPVMvalue = $item.Value.IP
                          if($SSHSesionVM){
                                Write-Log "Adding DNS config in $IPVMvalue......" -Path $LogFileName -Level Info
                                Adding-DNS2
                                Remove-SSHSession -SessionId 0 | Out-Null
                          }else{
                          
                          Write-Log "SSH Connection could not be established with $IPVMvalue" -Path $LogFileName -Level Error
                                                   
                          }                                                                    
                   }
                }
#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
}
 
Function Config-VMNFSFiles2{

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$secpasswd = ConvertTo-SecureString "Netapp1!" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("root", $secpasswd)

#Start-Sleep 45

   #Opening ssh sessions
   ForEach($item in $Global:config.VMs.GetEnumerator()){
                    
                  if (Test-Connection -ComputerName $item.Value.IP -Quiet) {

                          $SSHSesionVM = New-SSHSession -ComputerName $item.Value.IP -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120
                          $IPVMvalue = $item.Value.IP
                                        if($SSHSesionVM){
                                        Write-Log "Mounting NFS Volumes in $IPVMvalue......" -Path $LogFileName -Level Info
                                        Mounting-NFSVolumes2($item.Value.Name)
                                        Remove-SSHSession -SessionId 0 | Out-Null
                          
                          }else{
                          
                          Write-Log "SSH Connection could not be established with $IPVMvalue" -Path $LogFileName -Level Error
                 
                          }                                                                    
                   }
                }
#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
}
 
Function Shared-Files($SVM_Prefix, $CurrentPath){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

        $secpasswd = ConvertTo-SecureString "Netapp1!" -AsPlainText -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ("root", $secpasswd)
        $DataAggr = $Global:DataAggr
        $NFSvol  = "SharedFiles"
        $JunctionPath = "/"+$NFSvol
        
        #Export Policy is needed for the ShareFolder (iSCSI), NFS workflow does it automatic. 
        if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "FCP")){
        
         New-NcExportPolicy -Name "$SVM_NAME" -VserverContext "$SVM_NAME" | Out-Null
         #This is to change the policy on the root volume so that we can map the SharedFiles volume on the VMs
         $attr = Get-NcVol -Template
         Initialize-NcObjectProperty -Object $attr -Name VolumeExportAttributes | Out-Null
         $attr.VolumeExportAttributes.Policy = "$SVM_NAME"
         $query = Get-NcVol -Template
         $query.Name = "vdbench_root"
         $query.Vserver = "$SVM_NAME"
         Update-NcVol -Query $query -Attributes $attr -FlexGroupVolume:$false | Out-Null

        }

        New-NcVol -Name $NFSvol -Aggregate $DataAggr[0].Name -Size 5GB -JunctionPath $JunctionPath -ExportPolicy "$SVM_NAME" -SecurityStyle "Unix" -UnixPermissions "0777" -State "online" -VserverContext "$SVM_NAME" | Out-Null
        $DATALIF =  $Global:config.VMsLIF.lif0.IP


        ForEach($item in $Global:config.VMs.GetEnumerator() | Sort Key){
        
        New-NcExportRule -Policy "$SVM_NAME" -ClientMatch $item.Value.IP -ReadOnlySecurityFlavor any -ReadWriteSecurityFlavor any -VserverContext "$SVM_NAME" | Out-Null

        }

        $Localfile = $Global:config.Other.Pathvdbench

        if (!(Test-Path $Localfile)) {

        Write-Log "$Localfile absent in the Path.... " -Path $LogFileName -Level Warn
        Write-Log "Please select the path for vdbench binaries.... " -Path $LogFileName -Level Warn
        $Localfile_Array = Get-FileName $CurrentPath "zip"
        # $Localfile_Array is an array
        $Localfile = $Localfile_Array[0]
                
        }

        ForEach($item in $Global:config.VMs.GetEnumerator() | Sort Key){
                        #Export Policies and Rules 
                        New-NcExportPolicy -Name $item.Value.Name -VserverContext "$SVM_NAME" | Out-Null
                        New-NcExportRule -Policy $item.Value.Name -ClientMatch $item.Value.IP -ReadOnlySecurityFlavor any -ReadWriteSecurityFlavor any -VserverContext "$SVM_NAME" | Out-Null
                        $IPVMvalue = $item.Value.IP
                        Write-Log "Changing vdbench files in $IPVMvalue......" -Path $LogFileName -Level Info                       
                        New-SSHSession -ComputerName $IPVMvalue -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120 | Out-Null
                        $PermanentMount = "echo '$DATALIF`:/$NFSvol /root/$NFSvol nfs defaults        0 0' >> /etc/fstab"
                        $Mount = "mount -t nfs $DATALIF`:/$NFSvol /root/$NFSvol"
                        $Folder = "mkdir /root/$NFSvol"
                        $Folder1 = "mkdir /root/vdbench50406"
                        #New SFTP Session
                        New-SFTPSession -ComputerName $IPVMvalue -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120 | Out-Null
                        #Upload the files to Centos VM....
                        Write-Log "Importing and Extracting vdbench binaries to $IPVMvalue......" -Path $LogFileName -Level Info                       
                        Set-SFTPFile -SessionId 0 -LocalFile $Localfile -RemotePath /root/ | Out-Null
                        # Disconnect SFTP session
                        Remove-SFTPSession -SessionId 0 | Out-Null
                        #Extract zip file....
                        $UnzipFile = "unzip /root/vdbench50406.zip -d /root/vdbench50406"
                        #making vdbench executable
                        $chmodCommand = "chmod +x /root/vdbench50405/vdbench"
                        $exportPATH = "echo 'export PATH=/root/vdbench50406:`$PATH' >>~/.bash_profile "
                        #1. Creating the Folders Command
                        Invoke-SSHCommand -Index 0 -Command $Folder | Out-Null
                        Invoke-SSHCommand -Index 0 -Command $Folder1 | Out-Null
                        #2. adding the Permanent NFS mounting point
                        Invoke-SSHCommand -Index 0 -Command $PermanentMount | Out-Null
                        #3. Mounting the NFS vol
                        Invoke-SSHCommand -Index 0 -Command $Mount | Out-Null
                        #4. Extract zip file
                        Invoke-SSHCommand -Index 0 -Command $UnzipFile | Out-Null
                        #5. Making vdbench executable.
                        Invoke-SSHCommand -Index 0 -Command $chmodcommand | Out-Null
                        #6. Adding vdbench folder to $PATH
                        Invoke-SSHCommand -Index 0 -Command $exportPATH | Out-Null
                        #7. Adding IP Address to .rhosts file
                                ForEach($item2 in $Global:config.VMs.GetEnumerator() | Sort Key){
                                        $VMIP = $item2.Value.IP
                                        $rhostsfile = "echo '$VMIP    root' >> /root/.rhosts"
                                        
                                        Invoke-SSHCommand -Index 0 -Command $rhostsfile | Out-Null
                                 }
                        Remove-SSHSession -SessionId 0 | Out-Null
        
                }
        
        #Copy config Files to the Shared Folder

        $sharedFolder = "cp -r /root/AFF-POC-Toolkit-1.3/* /root/$NFSvol"
        New-SSHSession -ComputerName $item.Value.IP -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120 | Out-Null
        Invoke-SSHCommand -Index 0 -Command $sharedFolder | Out-Null
        Remove-SSHSession -SessionId 0 | Out-Null      

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function vdbench-Files2($SVM_Prefix){
 
        # $Global:PathNameFiles is an array
        # $Global:PathNameFiles[0] is the Configuratiton path.
        # $Global:PathNameFiles[1] is the log name.

        $ConfigFilePath = $Global:PathNameFiles[0]
        $LogFileName = $Global:PathNameFiles[1]
       
        #Converting string to Int32
        $strNumberofVolumesPerVM = $Global:config.Other.NumberofVolumesPerVM
        $BooleanValue = $strNumberofVolumesPerVM -match "^[0-9]{1,4}"
        $HasValue = $Matches
        $StrValue = $HasValue.Values
        [int]$NumberofVolumesPerVM = [convert]::ToInt32($StrValue, 10)
        
        $secpasswd = ConvertTo-SecureString "Netapp1!" -AsPlainText -Force
        $mycreds = New-Object System.Management.Automation.PSCredential ("root", $secpasswd)

        #Open a session in one of the VM where Sharefolder has ben mounted
        New-SSHSession -ComputerName $Global:config.VMs.VM00.IP -Credential $mycreds -AcceptKey -ConnectionTimeout 240 -OperationTimeout 240 | Out-Null
        
        if($SVM_Prefix -eq "NFS"){
        
            # Modify Hostfile at /root/SharedFiles/vdbench/nfs/aff-hosts-nfs.
            # hd=slave01,system=centos701,user=root
            # Delete the last 6 lines of the File
            $DeleteLine0 = "sed -i '37,42d' /root/SharedFiles/vdbench/nfs/aff-hosts-nfs"    
            Invoke-SSHCommand -Index 0 -Command $DeleteLine0 | Out-Null
        
            # Delete all lines at /root/SharedFiles/vdbench/nfs/aff-luns-nfs.
            $DeleteLine1 = "sed -i '15,45d' /root/SharedFiles/vdbench/nfs/aff-luns-nfs"    
            Invoke-SSHCommand -Index 0 -Command $DeleteLine1 | Out-Null

            #Add the size of the file Line.
            $SizeFile = $Global:config.Other.FileSize
            $sizeFileLine = "echo 'sd=default,size=$SizeFile,count=(1,5)' >> /root/SharedFiles/vdbench/nfs/aff-luns-nfs"
                        
            Invoke-SSHCommand -Index 0 -Command $sizeFileLine | Out-Null
            Remove-SSHSession -SessionId 0 | Out-Null
            $SlaveNumber = 0
        
        }elseif($SVM_Prefix -eq "iSCSI"){
        
            # Modify Hostfile at /root/SharedFiles/vdbench/vmdk/aff-hosts-vmdk.
            # hd=slave01,system=centos701,user=root
            # Delete the last 6 lines of the File
            $DeleteLine0 = "sed -i '37,60d' /root/SharedFiles/vdbench/vmdk/aff-hosts-vmdk"    
            Invoke-SSHCommand -Index 0 -Command $DeleteLine0 | Out-Null
        
            # Delete all lines at /root/SharedFiles/vdbench/vmdk/aff-luns-vmdk.
            $DeleteLine1 = "sed -i '12,45d' /root/SharedFiles/vdbench/vmdk/aff-luns-vmdk"    
            Invoke-SSHCommand -Index 0 -Command $DeleteLine1 | Out-Null

            #size of the file Line is not needed for iSCSI/vmdks
            #$SizeFile = $Global:config.Other.FileSize
            #$sizeFileLine = "echo 'sd=default,size=$SizeFile,count=(1,5)' >> /root/SharedFiles/vdbench/vmdk/aff-luns-vmdk"
            #Invoke-SSHCommand -Index 0 -Command $sizeFileLine | Out-Null
        
            Remove-SSHSession -SessionId 0 | Out-Null
            $SlaveNumber = 0
            }elseif($SVM_Prefix -eq "FCP"){
            # Modify Hostfile at /root/SharedFiles/vdbench/fcp/aff-hosts-fcp.
            # hd=slave01,system=centos701,user=root
            # Delete the last 6 lines of the File
            $DeleteLine0 = "sed -i '32,37d' /root/SharedFiles/vdbench/fcp/aff-hosts-fcp"    
            Invoke-SSHCommand -Index 0 -Command $DeleteLine0 | Out-Null
        
            # Delete all lines at /root/SharedFiles/vdbench/fcp/aff-luns-fcp.
            $DeleteLine1 = "sed -i '14,42d' /root/SharedFiles/vdbench/fcp/aff-luns-fcp"    
            Invoke-SSHCommand -Index 0 -Command $DeleteLine1 | Out-Null

            #size of the file Line is not needed for FCP
            #$SizeFile = $Global:config.Other.FileSize
            #$sizeFileLine = "echo 'sd=default,size=$SizeFile,count=(1,5)' >> /root/SharedFiles/vdbench/fcp/aff-luns-fcp"
            #Invoke-SSHCommand -Index 0 -Command $sizeFileLine | Out-Null
        
            Remove-SSHSession -SessionId 0 | Out-Null
            $SlaveNumber = 0
        }
  
        ForEach($item1 in $Global:config.VMs.GetEnumerator() | Sort Key){    
                
                New-SSHSession -ComputerName $item1.Value.IP -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120 | Out-Null
                
                if($SVM_Prefix -eq "NFS"){
                
                    #FOR is each SlaveXX
                    #Adding the new Lines at /root/SharedFiles/vdbench/nfs/aff-hosts-nfs
                    $VMName = $item1.Value.Name
                    $SlaveLine = "hd=slave0$SlaveNumber,system=$VMName,user=root"
                    $SlaveLine = "echo '$SlaveLine' >> /root/SharedFiles/vdbench/nfs/aff-hosts-nfs"
                    Invoke-SSHCommand -Index 0 -Command $SlaveLine | Out-Null

                    #Adding the new Lines at /root/SharedFiles/vdbench/nfs/aff-luns-nfs
                    #sd=sd1-1,host=slave01,lun=/mnt/vdbenchTest00_NFS_VD_vol1/file1-*,openflags=o_direct
                    #/vdbench_NFS00_NFS_VD_vol_1
                    #sd=sd1-1,host=slave01,lun=/mnt/vdbench_NFS00_NFS_VD_vol1/file1-*,openflags=o_direct
                    #sd=sd1-2,host=slave01,lun=/mnt/vdbench_NFS00_NFS_VD_vol2/file1-*,openflags=o_direct
                    #sd=sd1-3,host=slave01,lun=/mnt/vdbench_NFS00_NFS_VD_vol3/file1-*,openflags=o_direct
                    #sd=sd1-4,host=slave01,lun=/mnt/vdbench_NFS00_NFS_VD_vol4/file1-*,openflags=o_direct
           
                for($i=1; $i -lt ($NumberofVolumesPerVM+1); $i++){
                    $VolumeLine = "sd=sd$SlaveNumber-$i,host=slave0$SlaveNumber,lun=/mnt/$VMName`_NFS_VD_vol_$i/file1-*,openflags=o_direct"
                    $VolumeLine = "echo '$VolumeLine' >> /root/SharedFiles/vdbench/nfs/aff-luns-nfs"
                    Invoke-SSHCommand -Index 0 -Command $VolumeLine | Out-Null
                }
                
                $VolumeLine1 = "      "
                $VolumeLine1 = "echo '$VolumeLine1' >> /root/SharedFiles/vdbench/nfs/aff-luns-nfs"
                Invoke-SSHCommand -Index 0 -Command $VolumeLine1 | Out-Null                           
                $SlaveNumber++
                Remove-SSHSession -SessionId 0 | Out-Null
                
                }elseif($SVM_Prefix -eq "iSCSI"){
                
                    #FOR is each SlaveXX
                    #Adding the new Lines at /root/SharedFiles/vdbench/vmdk/aff-hosts-vmdk
                    $VMName = $item1.Value.Name
                    $SlaveLine = "hd=slave0$SlaveNumber,system=$VMName,user=root"
                    $SlaveLine = "echo '$SlaveLine' >> /root/SharedFiles/vdbench/vmdk/aff-hosts-vmdk"
                    Invoke-SSHCommand -Index 0 -Command $SlaveLine | Out-Null

                    #Adding the new Lines at /root/SharedFiles/vdbench/vmdk/aff-luns-vmdk
                    #sd=sd1-1,host=slave01,lun=/dev/sdb,openflags=o_direct,offset=0
                    #sd=sd1-2,host=slave01,lun=/dev/sdc,openflags=o_direct,offset=0
                    #sd=sd1-3,host=slave01,lun=/dev/sdd,openflags=o_direct,offset=0
                    #sd=sd1-4,host=slave01,lun=/dev/sde,openflags=o_direct,offset=0
                                
                    $letters = [char[]]('b'[0]..'z'[0])

                for($i=1; $i -lt ($NumberofVolumesPerVM+1); $i++){
                    $letters1 = $letters[($i-1)]
                    $VolumeLine = "sd=sd$SlaveNumber-$i,host=slave0$SlaveNumber,lun=/dev/sd$letters1,openflags=o_direct,offset=0"
                    $VolumeLine = "echo '$VolumeLine' >> /root/SharedFiles/vdbench/vmdk/aff-luns-vmdk"
                    Invoke-SSHCommand -Index 0 -Command $VolumeLine | Out-Null

                }
                
                    $VolumeLine1 = "      "
                    $VolumeLine1 = "echo '$VolumeLine1' >> /root/SharedFiles/vdbench/vmdk/aff-luns-vmdk"
                    Invoke-SSHCommand -Index 0 -Command $VolumeLine1 | Out-Null            
                    $SlaveNumber++
                    Remove-SSHSession -SessionId 0 | Out-Null
             
                }elseif($SVM_Prefix -eq "FCP"){
                
                    #FOR is each SlaveXX
                    #Adding the new Lines at /root/SharedFiles/vdbench/fcp/aff-hosts-fcp
                    $VMName = $item1.Value.Name
                    $SlaveLine = "hd=slave0$SlaveNumber,system=$VMName,user=root"
                    $SlaveLine = "echo '$SlaveLine' >> /root/SharedFiles/vdbench/fcp/aff-hosts-fcp"
                    Invoke-SSHCommand -Index 0 -Command $SlaveLine | Out-Null

                    #Adding the new Lines at /root/SharedFiles/vdbench/fcp/aff-luns-fcp
                    #sd=sd1-1,host=slave01,lun=/dev/sdb,openflags=o_direct,offset=0
                    #sd=sd1-2,host=slave01,lun=/dev/sdc,openflags=o_direct,offset=0
                    #sd=sd1-1,host=slave01,lun=/dev/sdd,openflags=o_direct,offset=0
                    #sd=sd1-2,host=slave01,lun=/dev/sde,openflags=o_direct,offset=0
                    $letters = [char[]]('b'[0]..'z'[0]) 
                for($i=1; $i -lt ($NumberofVolumesPerVM+1); $i++){
                    $letters1 = $letters[($i-1)]
                    $VolumeLine = "sd=sd$SlaveNumber-$i,host=slave0$SlaveNumber,lun=/dev/sd$letters1,openflags=o_direct,offset=0"
                    $VolumeLine = "echo '$VolumeLine' >> /root/SharedFiles/vdbench/fcp/aff-luns-fcp"
                    Invoke-SSHCommand -Index 0 -Command $VolumeLine | Out-Null
                }
                
                    $VolumeLine1 = "      "
                    $VolumeLine1 = "echo '$VolumeLine1' >> /root/SharedFiles/vdbench/fcp/aff-luns-fcp"
                    Invoke-SSHCommand -Index 0 -Command $VolumeLine1 | Out-Null                                    
                    $SlaveNumber++
                    Remove-SSHSession -SessionId 0 | Out-Null
 
                }


        }

        if($Global:config.Other.Jumbo){
                ForEach($item1 in $Global:config.VMs.GetEnumerator() | Sort Key){
                New-SSHSession -ComputerName $item1.Value.IP -Credential $mycreds -AcceptKey -ConnectionTimeout 120 -OperationTimeout 120 | Out-Null
                #Changing the MTU to 9000 at /etc/sysconfig/network-scripts
                $MTULine = "MTU=9000"
                $MTULine = "echo '$MTULine' >> /etc/sysconfig/network-scripts/ifcfg-eno16777984"
                Invoke-SSHCommand -Index 0 -Command $MTULine | Out-Null
                #Reboot the network
                Invoke-SSHCommand -Index 0 -Command "systemctl restart network" | Out-Null
                Remove-SSHSession -SessionId 0 | Out-Null
             }
        }

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

Write-Log "Deployment has Finished......" -Path $LogFileName -Level Info
}
 
Function Remove-VMsDatatore($SVM_Prefix){

$LogFileName = $Global:PathNameFiles[1]

#Connecting to VCenter....
if(($SVM_Prefix -eq "iSCSI") -or ($SVM_Prefix -eq "NFS")){

$DataStoreName = $Global:config.VMsLIF.lif0.Name

}elseif($SVM_Prefix -eq "FCP"){

$DataStoreName = $Global:config.VMsLIF.lif1.Name

}
$ESXiHost = $Global:config.Hosts.Host00.Name
$SVM_NAME = $Global:config.SVM.Name

$ConnetionVCenter = Connect-Vcenter $ConnectedVcenter -LogFilePath $LogFileName

if($ConnetionVCenter -eq "Stop"){

    Write-Log "We failed to connected to Vcenter $ConnectedVcenter" -Path $LogFileName -Level Error
    Return "CancelDeletionVMs"
    Break
}


$HostDataStores = Get-Datastore -Name $DataStoreName -ErrorAction SilentlyContinue | Get-VMHost -ErrorVariable Err -ErrorAction SilentlyContinue

#Delete the Customazation in case the Script was run before. 
$CurrentOSSpecs = Get-OSCustomizationSpec -Name "$SVM_NAME*"

if($CurrentOSSpecs.Count -gt 0){

Remove-OSCustomizationSpec -OSCustomizationSpec "$SVM_NAME*" -Confirm:$false | Out-Null

}
       
   if($HostDataStores){
        
        do{
        Write-Log "Are you sure you want to Delete vdbench VMs and NFS Datastore:  "  -Path $LogFileName -Level Warn
        $Creation = Read-Host "(No/Yes)"
        Write-Log " " -Path $LogFileName -Level Info      
        if($Creation -eq "Yes"){
                #Removing all VMs                
                 ForEach($VM in $Global:config.VMs.GetEnumerator() | Sort Key){
                 $VMName = $VM.Value.Name
                 #Check if the VM even exist..
                 $VMOnline = Get-VM -Name $VMName -ErrorAction SilentlyContinue
                 if($VMOnline){
                 Stop-VM -VM $VMName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                 Remove-VM -DeletePermanently -VM $VMName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                 }           
                }
                
                $TemplateOVA = Get-Template -Name vdbench-template -ErrorAction SilentlyContinue
                if($TemplateOVA){
                Remove-Template -Template vdbench-template -DeletePermanently -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                }
                
                $VSwitch = Get-VirtualSwitch -VMHost $ESXiHost -Standard -Name vdbench -ErrorAction SilentlyContinue

                if($VSwitch){
                              
                $PortGroup = Get-VMHost -Name $ESXiHost | Get-VirtualPortGroup -Name "VM Network" -VirtualSwitch $VSwitch -Standard
                Remove-VirtualPortGroup -VirtualPortGroup $PortGroup -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                Write-Log "Deleting a Port Group vdbench that used to import OVA......" -Path $LogFileName -Level Info
                Remove-VirtualSwitch -VirtualSwitch $VSwitch -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                Write-Log "Deleting the VSwitch that was used to import OVA......" -Path $LogFileName -Level Info

                }
                                
                Write-Log " Removing All VMs ......" -Path $LogFileName -Level Info

                if($SVM_Prefix -eq "NFS"){
                    foreach($Hostvdbench in $HostDataStores){

                    Write-Log " Removing NFS Datastore in "+$Hostvdbench.Name -Path $LogFileName -Level Info

                    Remove-Datastore -Datastore $DataStoreName -VMHost $Hostvdbench.Name -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    }
                    }elseif($SVM_Prefix -eq "iSCSI"){
                    
                    Write-Log " Removing iSCSI Datastore.... " -Path $LogFileName -Level Info

                    Remove-Datastore -Datastore $DataStoreName -VMHost $Global:config.Hosts.Host00.Name -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    
                    #Removing the iSCSI Targets from VCenter...
                            foreach($iSCSILIF in $Global:config.LIFSiSCSI.GetEnumerator()){

                            Write-Log "Removing iSCSI Target on ESXi Servers: " -Path $LogFileName -Level Info
                            $iSCSILIFPort = $iSCSILIF.Value.IP+":3260"
                            Remove-IScsiHbaTarget -Target (Get-IScsiHbaTarget -Address $iSCSILIFPort -Type Send) -Confirm:$false -ErrorAction SilentlyContinue

                            }                   
                    #Scanning HBAs
                            foreach($H in $Global:config.Hosts.GetEnumerator()){
 
                            $HostName = $H.Value.Name
                            Write-Log "Refreshing HBAs on ESXi Server: $HostName" -Path $LogFileName -Level Info
                            Get-VMHostStorage -VMHost $HostName -Refresh -RescanAllHba | Out-Null
 
                            }
                    }elseif($SVM_Prefix -eq "FCP"){
                    
                    Write-Log " Removing FCP Datastore.... " -Path $LogFileName -Level Info

                    Remove-Datastore -Datastore $DataStoreName -VMHost $Global:config.Hosts.Host00.Name -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                    
                     #Scanning HBAs
                            foreach($H in $Global:config.Hosts.GetEnumerator()){
 
                            $HostName = $H.Value.Name
                            Write-Log "Refreshing HBAs on ESXi Server: $HostName" -Path $LogFileName -Level Info
                            Get-VMHostStorage -VMHost $HostName -Refresh -RescanAllHba | Out-Null
 
                            }


                    }
                   
            }elseif($Creation -eq "No"){
        
        Write-Log "The vdbench VMs and the NFS Datastore were not deleted"  -Path $LogFileName -Level Warn
        $continue = $true
        }else{
        
        Write-Log "Incorrect option selected, please enter Yes or No..."  -Path $LogFileName -Level Warn
        
        }
        }While( !(($Creation -eq "No") -or ($Creation -eq "Yes") ))

        }else{
        
        Write-Log " VMs cant be found as there is no DataStore called $DataStoreName "  -Path $LogFileName -Level Warn
        
        }
#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Remove-ncVserverVD($SVM_Prefix) {

$LogFileName = $Global:PathNameFiles[1]

#Connecting to NetApp Controller.....
$SVM_NAME = $Global:config.SVM.Name+"_"+$SVM_Prefix

$ConnectionNetApp = Connect-NetApp $global:CurrentNcController -LogFilePath $LogFileName

if($ConnectionNetApp -eq "Stop"){
    
    Write-Log "We failed to connected to NetApp Controller $global:CurrentNcController"  -Path $LogFileName -Level Error
    Return "CancelDeletionSVM"
    Break
}
        
        do{
        Write-Log "Are you sure you want to Delete $SVM_NAME SVM with all volumes " -Path $LogFileName -Level Warn
        $Creation = Read-Host "(No/Yes)"
        Write-Log " " -Path $LogFileName -Level Info 
        if($Creation -eq "Yes"){
         $Vservers = Get-NcVserver 
            if ($Vservers.Vserver -Notcontains "$SVM_NAME"){
                    Write-Log "There is no SVM under the name vdbench, please create it by going to the main Menu " -Path $LogFileName -Level Warn
                    
                }else{
                      Write-Log "Deleting SVM vdbench.... " -Path $LogFileName -Level Info
                      $VolumesVserver = Get-NcVol -Vserver "$SVM_NAME" | ?{ $_.VolumeStateAttributes.IsVserverRoot -eq $false }
                      $RootVolume =  Get-NcVol -Vserver "$SVM_NAME" | ?{ $_.VolumeStateAttributes.IsVserverRoot -eq $true }

                                foreach($Volume in $VolumesVserver){
                                    Write-Log "Deleting Data Volume $Volume.... " -Path $LogFileName -Level Info
                                    Dismount-NcVol -Name $Volume.Name -Force -VserverContext "$SVM_NAME" -Confirm:$false | Out-Null
                                    Set-NcVol $Volume.Name -VserverContext "$SVM_NAME" -Offline -Confirm:$false | Out-Null
                                    Remove-NcVol $Volume.Name -VserverContext "$SVM_NAME" -Confirm:$false | Out-Null
                                }
                                Set-NcVol $RootVolume.Name -VserverContext "$SVM_NAME" -Offline -Confirm:$false | Out-Null
                                Remove-NcVol $RootVolume.Name -VserverContext "$SVM_NAME" -Confirm:$false | Out-Null
                }
                
                $igroup = Get-NcIgroup -Name "vdbench" -VserverContext "$SVM_NAME"
                if($igroup){
                Remove-NcIgroup -Name "vdbench" -VserverContext "$SVM_NAME" -Confirm:$false
                }
                Remove-NcVserver -Name "$SVM_NAME" -Confirm:$false | Out-Null
               
        }elseif($Creation -eq "No"){
        Write-Log "The SVM vdbench was not deleted" -Path $LogFileName -Level Warn
        $continue = $true
        }else{
        Write-Log "Incorrect option selected, please enter Yes or No..."  -Path $LogFileName -Level Warn
        }
        }while(!(($Creation -eq "No") -or ($Creation -eq "Yes") ))

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }
Clear-Host
      
}
 
Function PS-VersionCheck{

$PSVersion = $PSversiontable.PSVersion

if($PSVersion.Major -ge 5){

return $true

}else{

return $false

}


}
 
Function PowerCLI-VersionCheck{
# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$LogFileName = "PreChecks_Log.log" 
  
$PowerCLIVersion = Get-Module -Name VMware.PowerCLI -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$PowerCLIVersion = $PowerCLIVersion.Version

if($PowerCLIVersion.Major -ge 6){

return $true
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

}else{

return $false

}

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function POSH-SHH-VersionCheck{

$LogFileName = "PreChecks_Log.log"

$PSSHHVersion = Get-Module -Name Posh-SSH -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
$PSSHHVersion = $PSSHHVersion.Version

if($PSSHHVersion.Major -eq 1){

return $true

}else{

return $false

}

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function PSNetAppToolKit-VersionCheck{

$LogFileName = "PreChecks_Log.log"

$OntapDataVersion = Get-NaToolkitVersion -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

if($OntapDataVersion.Major -ge 4){

return $true

}else{

return $false

}

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function VSwitch-Check($ESXiHost){

# $Global:PathNameFiles is an array
# $Global:PathNameFiles[0] is the Configuratiton path.
# $Global:PathNameFiles[1] is the log name.

$ConfigFilePath = $Global:PathNameFiles[0]
$LogFileName = $Global:PathNameFiles[1]

$VMNetwork = Get-VirtualPortGroup -Name "VM Network" -VMHost $ESXiHost -ErrorAction SilentlyContinue

if($VMNetwork){

return $true

}else{

return $false

}

#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function Pre-Checks{

$LogFileName = "PreChecks_Log.log"

Write-Log "Checking Powershell Version....." -Path $LogFileName -Level Info

$PSVersion = $PSversiontable.PSVersion

    if(PS-VersionCheck){
    $PowerCLIVersion = Get-Module -Name VMware.PowerCLI -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $PowerCLIVersion = $PowerCLIVersion.Version
    $PSSHHVersion = Get-Module -Name Posh-SSH -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $PSSHHVersion = $PSSHHVersion.Version
    
    Write-Log "Current version $PSVersion of PowerShell is supported...." -Path $LogFileName -Level Info

    }else{
    
    Write-Log "Current version $PSVersion of Powershell is not supported...." -Path $LogFileName -Level Error
    Write-Log "Please install POSH Version 5, restart the computer and relaunch the script.... " -Path $LogFileName -Level Error
    [void][System.Console]::ReadKey($true)
    Exit

    }

    if(PowerCLI-VersionCheck){
    
    Write-Log "Current version $PowerCLIVersion of PowerCLI is supported...." -Path $LogFileName -Level Info
    
    }else{
            
            do{
            Write-Log "Current version $PowerCLIVersion of PowerCLI is not supported or PowerCLI is not installed...." -Path $LogFileName -Level Error
            $Install = Read-Host "Do you want to install the lastest version? Yes/No "
            if($Install -eq "Yes"){
    
            Install-Module -Name VMware.PowerCLI –Scope CurrentUser -Confirm:$false
            Import-Module -Name VMware.PowerCLI -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-PowerCLIConfiguration -InvalidCertificateAction Ignore
            
            }elseif($Install -eq "No"){
            
            Write-Log "PowerCLI was not installed.... " -Path $LogFileName -Level Error
            [void][System.Console]::ReadKey($true)
            Exit

            }else{
            
            Write-Log "Incorrect option selected, please enter Yes or No..."  -Path $LogFileName -Level Warn
            
            }
            }while(!(($Install -eq "No") -or ($Install -eq "Yes") ))

    }

    if(POSH-SHH-VersionCheck){
    $OntapDataVersion = Get-NaToolkitVersion -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    Write-Log "Current version $PSSHHVersion of POSH-SSH is supported...." -Path $LogFileName -Level Info
    }else{
            
            do{
            Write-Log "Current version $PSSHHVersion of POSH-SSH is not supported or POSH-SSH is not even installed...." -Path $LogFileName -Level Error
            $Install = Read-Host "Do you want to install the lastest version? Yes/No "
            if($Install -eq "Yes"){
    
            Install-Module -Name Posh-SSH -Scope CurrentUser -Force -RequiredVersion 1.7.7 -Confirm:$false
            #Import Posh-SSH Module....
            Import-Module -Name Posh-SSH -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            }elseif($Install -eq "No"){
            
            Write-Log "POSH-SSH was not installed.... " -Path $LogFileName -Level Error
            [void][System.Console]::ReadKey($true)
            Exit

            }else{
            
            Write-Log "Incorrect option selected, please enter Yes or No..."  -Path $LogFileName -Level Warn
            
            }

            }While(!(($Creation -eq "No") -or ($Creation -eq "Yes") ))

    }


    if(PSNetAppToolKit-VersionCheck){
    
    Write-Log "Current version $OntapDataVersion of NetApp Powershell tool kit is supported...." -Path $LogFileName -Level Info
    
    }else{
    
    Write-Log "Current version $OntapDataVersion of NetApp Powershell tool kit is not supported or it is not installed...." -Path $LogFileName -Level Error
    Write-Log "Please install the latest version NetApp Powershell tool kit and relaunch the script.... " -Path $LogFileName -Level Error
    [void][System.Console]::ReadKey($true)
    Exit
    
    }
#Adding Error to Log File
if($Error) { $Error | %{ Write-Log -Message $_ -Message2 $_.InvocationInfo.PositionMessage -Path $LogFilename -Level Error } }

}
 
Function GenerateConfigFile{

$RawXAML  = @"

<Window x:Class="GenerationConfigFile.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:GenerationConfigFile"
        mc:Ignorable="d"
        Title="Generation of the Configuration File" Height="1360.163" Width="818.089">
    <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="0,0,0,1">
        <Grid Height="1417" Background="#FFE5E5E5">
            <Expander x:Name="VMwareConfigurationExpander" Header="VMWare Configuration" Height="880" Margin="19,133,47,0" VerticalAlignment="Top" FontWeight="Bold">
                <Grid x:Name="VMWareConfigurationGrid" Background="#FFE5E5E5" Margin="0,0,-2,0">
                    <Label Content="Even Number of Volumes per VM : " HorizontalAlignment="Left" Height="30" Margin="20,80,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="VCenter IP/HostName :" HorizontalAlignment="Left" Height="30" Margin="20,45,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="NetApp Cluster IP Address : " HorizontalAlignment="Left" Height="36" Margin="20,10,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="Number of VM per ESXi Host : " HorizontalAlignment="Left" Height="36" Margin="20,115,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="Volume/ LUN size in GB : " HorizontalAlignment="Left" Height="36" Margin="20,150,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="DVSwitch :  " HorizontalAlignment="Left" Height="36" Margin="20,185,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="VM Network Name (Only DVSwitch) :  " HorizontalAlignment="Left" Height="36" Margin="20,220,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="VM Port Name (Only VSwitch) ;" HorizontalAlignment="Left" Height="36" Margin="20,255,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="Files Size in GB (Only for NFS) :" HorizontalAlignment="Left" Height="36" Margin="20,290,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="MTU Size : " HorizontalAlignment="Left" Height="36" Margin="20,320,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="Protocol : " HorizontalAlignment="Left" Height="36" Margin="20,345,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="LUN ID (Only for iSCSI/FC):" HorizontalAlignment="Left" Height="36" Margin="20,370,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="Path for vdbench binaries : " HorizontalAlignment="Left" Height="36" Margin="20,405,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <Label Content="Path for Centos OVA :" HorizontalAlignment="Left" Height="36" Margin="20,440,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <RadioButton x:Name="NFSRadioButton" Content="NFS" HorizontalAlignment="Left" Margin="250,352,0,0" VerticalAlignment="Top" Height="15" FontWeight="Bold" GroupName="Protocols"/>
                    <RadioButton x:Name="iSCSIRadioButton" Content="iSCSI" HorizontalAlignment="Left" Margin="310,352,0,0" VerticalAlignment="Top" FontWeight="Bold" GroupName="Protocols"/>
                    <RadioButton x:Name="FCRadioButton" Content="FC" HorizontalAlignment="Left" Margin="370,353,0,0" VerticalAlignment="Top" FontWeight="Bold" GroupName="Protocols"/>
                    <RadioButton x:Name="MTU1500RadioButton" Content="1500" HorizontalAlignment="Left" Margin="250,328,0,0" VerticalAlignment="Top" FontWeight="Bold" GroupName="Framesize"/>
                    <RadioButton x:Name="Jumbo" Content="9000" HorizontalAlignment="Left" Margin="310,328,0,0" VerticalAlignment="Top" FontWeight="Bold" GroupName="Framesize"/>
                    <TextBox x:Name="PathOVATextBox" KeyboardNavigation.TabIndex="10" HorizontalAlignment="Left" Height="30" Margin="249,440,0,0" TextWrapping="Wrap" Text="Enter the path here.." VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="PathvdbenchTextBox" KeyboardNavigation.TabIndex="9" HorizontalAlignment="Left" Height="30" Margin="249,405,0,0" TextWrapping="Wrap" Text="Enter the path here.." VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="NumberofVolumesPerVMTextBox" KeyboardNavigation.TabIndex="0" HorizontalAlignment="Left" Height="30" Margin="249,80,0,0" TextWrapping="Wrap" Text="Enter Even Number of Volumes per VM.." VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="VCenterIPTextBox" KeyboardNavigation.TabIndex="1" HorizontalAlignment="Left" Height="30" Margin="249,45,0,0" TextWrapping="Wrap" Text="Enter VCenter IP here.. " VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="ClusterIPTextBox" KeyboardNavigation.TabIndex="2" HorizontalAlignment="Left" Height="30" Margin="249,10,0,0" TextWrapping="Wrap" Text="Enter NetApp cluster IP here.." VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="VolumeSizeTextBox" KeyboardNavigation.TabIndex="4" HorizontalAlignment="Left" Height="30" Margin="249,150,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" Text="in GB"/>
                    <TextBox x:Name="NetworkNameTextBox" KeyboardNavigation.TabIndex="5" HorizontalAlignment="Left" Height="30" Margin="249,220,0,0" TextWrapping="Wrap" Text="Enter the VM Network Name of the DVSwitch..." VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="PortGroupNameTextBox" KeyboardNavigation.TabIndex="6" HorizontalAlignment="Left" Height="30" Margin="249,255,0,0" TextWrapping="Wrap" Text="Enter the VM Network Name of the VSwitch..." VerticalAlignment="Top" Width="393"/>
                    <TextBox x:Name="FileSizeTextBox" KeyboardNavigation.TabIndex="7" HorizontalAlignment="Left" Height="30" Margin="249,290,0,0" TextWrapping="Wrap" Text="Enter file size.." VerticalAlignment="Top" Width="100"/>
                    <TextBox x:Name="LunIDTextBox" KeyboardNavigation.TabIndex="8" HorizontalAlignment="Left" Height="30" Margin="249,370,0,0" TextWrapping="Wrap" Text="Enter LUN ID" VerticalAlignment="Top" Width="100"/>
                    <Expander x:Name="ESXiServersExpander" Header="ESXi Host" HorizontalAlignment="Left" Height="200" Margin="20,501,0,0" VerticalAlignment="Top" Width="620">
                        <Grid x:Name="ESXiServerExpanderGrid" Background="#FFE5E5E5" Width="620" Margin="0,0,-2,0">
                            <Button x:Name="ADDHOSTButton" Content="ADD ESXi HOST" HorizontalAlignment="Left" Height="41" Margin="130,7,0,0" VerticalAlignment="Top" Width="138"/>
                            <Label x:Name="ESXiSERVERLabel0" Content="ESXi Hostname 0 :" HorizontalAlignment="Left" Height="36" Margin="81,70,0,0" VerticalAlignment="Top" Width="123"/>
                            <TextBox x:Name="ESXiSERVERTextBox0" KeyboardNavigation.TabIndex="11" HorizontalAlignment="Left" Height="36" Margin="204,70,0,0" TextWrapping="Wrap" Text="Enter Hostname of the ESXi server 0" VerticalAlignment="Top" Width="281"/>
                            <Button x:Name="DELETEHOSTButton" Content="DELETE ESXi HOST" HorizontalAlignment="Left" Height="41" Margin="346,7,0,0" VerticalAlignment="Top" Width="138"/>
                        </Grid>
                    </Expander>
                    <Expander x:Name="VMExpander" Header="vdbench VMs" HorizontalAlignment="Left" Margin="20,574,0,0" Width="620" Height="230" VerticalAlignment="Top">
                        <Grid x:Name="VMExpanderGrid" Background="#FFE5E5E5" Width="620" Margin="0,0,-2,0">
                            <Button x:Name="ADDVMButton" Content="ADD vdbench VM" HorizontalAlignment="Left" Height="41" Margin="130,7,0,0" VerticalAlignment="Top" Width="138"/>
                            <Label x:Name="VMGatewayLabel" Content="Gateway :" HorizontalAlignment="Left" Height="36" Margin="81,70,0,0" VerticalAlignment="Top" Width="123"/>
                            <TextBox x:Name="VMGatewayTextBox" KeyboardNavigation.TabIndex="12" HorizontalAlignment="Left" Height="36" Margin="204,70,0,0" TextWrapping="Wrap" Text="Enter the gateway for the vdbench VMs..." VerticalAlignment="Top" Width="281"/>
                            <Button x:Name="DELETEVMButton" Content="DELETE vdbench VM" HorizontalAlignment="Left" Height="41" Margin="346,7,0,0" VerticalAlignment="Top" Width="138"/>
                            <Label x:Name="VMNetmaskLabel" Content="Netmask :" HorizontalAlignment="Left" Height="36" Margin="81,109,0,0" VerticalAlignment="Top" Width="123"/>
                            <TextBox x:Name="VMNetmaskTextBox" KeyboardNavigation.TabIndex="13" HorizontalAlignment="Left" Height="36" Margin="204,109,0,0" TextWrapping="Wrap" Text="Enter the Netmask for the vdbench VMs..." VerticalAlignment="Top" Width="281"/>
                            <Label x:Name="VMIPAddressLabel0" Content="IP Address VM 0 :" HorizontalAlignment="Left" Height="36" Margin="81,150,0,0" VerticalAlignment="Top" Width="123"/>
                            <TextBox x:Name="VMIPAddressTextBox0" KeyboardNavigation.TabIndex="14" HorizontalAlignment="Left" Height="36" Margin="204,150,0,0" TextWrapping="Wrap" Text="Enter the IP Address for the VM 0.." VerticalAlignment="Top" Width="281"/>
                        </Grid>
                    </Expander>
                    <RadioButton x:Name="VSWITCHRadioButton" Content="VSwitch" HorizontalAlignment="Left" Margin="251,192,0,0" VerticalAlignment="Top"/>
                    <RadioButton x:Name="DSwitchRadioButton" Content="DVSwitch" HorizontalAlignment="Left" Margin="364,192,0,0" VerticalAlignment="Top"/>
                    <TextBox x:Name="NumberVMperhostTextBox" KeyboardNavigation.TabIndex="3" HorizontalAlignment="Left" Height="30" Margin="249,116,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="100" Text="VMs per server.."/>
                </Grid>
            </Expander>
            <Expander x:Name="SVMConfigurationExpander" Header="SVM Configuration" Height="929" Margin="19,202,47,0" VerticalAlignment="Top" FontWeight="Bold" RenderTransformOrigin="0.5,0.5">
                <Grid Background="#FFE5E5E5" Margin="0,0,-2,0">
                    <Label Content="SVM Name : " HorizontalAlignment="Left" Height="30" Margin="20,10,0,0" VerticalAlignment="Top" Width="220" FontWeight="Bold"/>
                    <TextBox x:Name="SVMNameTextBox" KeyboardNavigation.TabIndex="15" HorizontalAlignment="Left" Height="30" Margin="249,10,0,0" TextWrapping="Wrap" Text="Enter SVM Name here.." VerticalAlignment="Top" Width="393"/>
                    <Expander x:Name="NFSIPCONFIGURATIONExpander" Header="NFS/iSCSI IP Configuration (DataStore/SharedFiles for NFS, iSCSI and FC) :" HorizontalAlignment="Left" Height="156" Margin="250,50,0,0" VerticalAlignment="Top" Width="450">
                        <Grid Background="#FFE5E5E5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="220*"/>
                                <ColumnDefinition Width="169*"/>
                            </Grid.ColumnDefinitions>
                            <Label Content="IP Address :" HorizontalAlignment="Left" Height="30" Margin="10,5,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Netmask :" HorizontalAlignment="Left" Height="30" Margin="10,65,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Gateway :" HorizontalAlignment="Left" Height="30" Margin="10,35,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port :" HorizontalAlignment="Left" Height="30" Margin="10,95,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <TextBox x:Name="NFSLIFIPTextBox" KeyboardNavigation.TabIndex="16" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,3,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address..."/>
                            <TextBox x:Name="NFSLIFNETMASKTextBox" KeyboardNavigation.TabIndex="18" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,65,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Netmask..."/>
                            <TextBox x:Name="NFSLIFGWTextBox" KeyboardNavigation.TabIndex="17" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,34,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Gateway..."/>
                            <TextBox x:Name="NFSLIFPORTTextBox" KeyboardNavigation.TabIndex="19" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,96,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port..."/>
                        </Grid>
                    </Expander>
                    <Expander x:Name="FCDATASTORECONFIGURATIONExpander" Header="Data FC Configuration and for DataStore :" HorizontalAlignment="Left" Height="252" Margin="250,80,0,0" VerticalAlignment="Top" Width="391">
                        <Grid Background="#FFE5E5E5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="220*"/>
                                <ColumnDefinition Width="169*"/>
                            </Grid.ColumnDefinitions>
                            <Label Content="FC Port (Datastore) :" HorizontalAlignment="Left" Height="30" Margin="10,7,0,0" VerticalAlignment="Top" Width="141" FontWeight="Bold"/>
                            <TextBox x:Name="FCLIFPORTDATASTORETextBox" KeyboardNavigation.TabIndex="20" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="156,7,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="107" Text="Enter FC port..."/>
                            <Label Content="FC Port (LIF 1 node1) :" HorizontalAlignment="Left" Height="30" Margin="10,42,0,0" VerticalAlignment="Top" Width="141" FontWeight="Bold"/>
                            <TextBox x:Name="DATAFCLIF1PORTNODE1TextBox" KeyboardNavigation.TabIndex="21" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="156,42,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="107" Text="Enter FC port..."/>
                            <Label Content="FC Port (LIF 2 node1) :" HorizontalAlignment="Left" Height="30" Margin="10,77,0,0" VerticalAlignment="Top" Width="141" FontWeight="Bold"/>
                            <TextBox x:Name="DATAFCLIF2PORTNODE1TextBox" KeyboardNavigation.TabIndex="22" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="156,77,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="107" Text="Enter FC port..."/>
                            <Label Content="FC Port (LIF 3 node2) :" HorizontalAlignment="Left" Height="30" Margin="10,110,0,0" VerticalAlignment="Top" Width="141" FontWeight="Bold"/>
                            <TextBox x:Name="DATAFCLIF1PORTNODE2TextBox" KeyboardNavigation.TabIndex="23" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="156,110,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="107" Text="Enter FC port..."/>
                            <Label Content="FC Port (LIF 4 node2) :" HorizontalAlignment="Left" Height="30" Margin="10,145,0,0" VerticalAlignment="Top" Width="141" FontWeight="Bold"/>
                            <TextBox x:Name="DATAFCLIF2PORTNODE2TextBox" KeyboardNavigation.TabIndex="24" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="156,145,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="107" Text="Enter FC port..."/>
                        </Grid>
                    </Expander>
                    <Expander x:Name="DATANFSIPCONFIGURATIONExpander" Header="Data NFS IP Configuration :" HorizontalAlignment="Left" Height="362" Margin="250,110,0,0" VerticalAlignment="Top" Width="450">
                        <Grid Background="#FFE5E5E5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="220*"/>
                                <ColumnDefinition Width="169*"/>
                            </Grid.ColumnDefinitions>
                            <Label Content="IP Address 1 :" HorizontalAlignment="Left" Height="30" Margin="10,65,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Netmask :" HorizontalAlignment="Left" Height="30" Margin="10,34,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Gateway :" HorizontalAlignment="Left" Height="30" Margin="10,3,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port  node 1 :" HorizontalAlignment="Left" Height="30" Margin="10,96,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <TextBox x:Name="DATANFSLIFGWTextBox" KeyboardNavigation.TabIndex="25" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,3,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Gateway for NFS traffic..."/>
                            <TextBox x:Name="DATANFSLIFIP1TextBox" KeyboardNavigation.TabIndex="27" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,65,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address 1 ..."/>
                            <TextBox x:Name="DATANFSLIFNETMASKTextBox" KeyboardNavigation.TabIndex="26" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,34,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Netmask for NFS traffic... "/>
                            <TextBox x:Name="DATANFSLIFPORT1TextBox" KeyboardNavigation.TabIndex="28" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,96,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port node 1..."/>
                            <Label Content="IP Address 2 :" HorizontalAlignment="Left" Height="30" Margin="10,128,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port  node 1 :" HorizontalAlignment="Left" Height="30" Margin="10,159,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <TextBox x:Name="DATANFSLIFIP2TextBox" KeyboardNavigation.TabIndex="29" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,128,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address 2 ..."/>
                            <TextBox x:Name="DATANFSLIFPORT2TextBox" KeyboardNavigation.TabIndex="30" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,159,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port node 1..."/>
                            <Label Content="IP Address 3 :" HorizontalAlignment="Left" Height="30" Margin="10,191,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port  node 2 :" HorizontalAlignment="Left" Height="30" Margin="10,222,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <TextBox x:Name="DATANFSLIFIP3TextBox" KeyboardNavigation.TabIndex="31" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,191,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address 3..."/>
                            <TextBox x:Name="DATANFSLIFPORT3TextBox" KeyboardNavigation.TabIndex="32" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,222,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port node 2..."/>
                            <Label Content="IP Address 4 :" HorizontalAlignment="Left" Height="30" Margin="10,255,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port  node 2 :" HorizontalAlignment="Left" Height="30" Margin="10,286,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <TextBox x:Name="DATANFSLIFIP4TextBox" KeyboardNavigation.TabIndex="33" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,255,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address 4..."/>
                            <TextBox x:Name="DATANFSLIFPORT4TextBox" KeyboardNavigation.TabIndex="34" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,286,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port node 2..."/>
                        </Grid>
                    </Expander>
                    <Expander x:Name="iSCSIIPCONFIGURATIONExpander" Header="Data iSCSI IP Configuration :" HorizontalAlignment="Left" Height="551" Margin="251,140,0,-184" VerticalAlignment="Top" Width="450">
                        <Grid Background="#FFE5E5E5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="220*"/>
                                <ColumnDefinition Width="169*"/>
                            </Grid.ColumnDefinitions>
                            <Label Content="IP Address 1 :" HorizontalAlignment="Left" Height="30" Margin="10,5,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Netmask 1 :" HorizontalAlignment="Left" Height="30" Margin="10,65,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Gateway 1 :" HorizontalAlignment="Left" Height="30" Margin="10,35,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port Node 1 :" HorizontalAlignment="Left" Height="30" Margin="10,95,0,0" VerticalAlignment="Top" Width="87" FontWeight="Bold"/>
                            <TextBox x:Name="DATAiSCSILIFIP1TextBox" KeyboardNavigation.TabIndex="35" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,3,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address..."/>
                            <TextBox x:Name="DATAiSCSILIFNETMASK1TextBox" KeyboardNavigation.TabIndex="37" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,65,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Netmask..."/>
                            <TextBox x:Name="DATAiSCSILIFGW1TextBox" KeyboardNavigation.TabIndex="36" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,34,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Gateway..."/>
                            <TextBox x:Name="DATAiSCSILIFPORT1TextBox" KeyboardNavigation.TabIndex="38" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,96,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port..."/>
                            <Label Content="IP Address 2 :" HorizontalAlignment="Left" Height="30" Margin="10,133,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Netmask 2 :" HorizontalAlignment="Left" Height="30" Margin="10,193,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Gateway 2 :" HorizontalAlignment="Left" Height="30" Margin="10,163,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port Node 2 :" HorizontalAlignment="Left" Height="30" Margin="10,223,0,0" VerticalAlignment="Top" Width="87" FontWeight="Bold"/>
                            <TextBox x:Name="DATAiSCSILIFIP2TextBox" KeyboardNavigation.TabIndex="38" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,131,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address..."/>
                            <TextBox x:Name="DATAiSCSILIFNETMASK2TextBox" KeyboardNavigation.TabIndex="40" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,193,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Netmask..."/>
                            <TextBox x:Name="DATAiSCSILIFGW2TextBox" KeyboardNavigation.TabIndex="39" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,162,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Gateway..."/>
                            <TextBox x:Name="DATAiSCSILIFPORT2TextBox" KeyboardNavigation.TabIndex="41" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,224,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port..."/>
                            <Label Content="IP Address 3 :" HorizontalAlignment="Left" Height="30" Margin="10,261,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Netmask 3 :" HorizontalAlignment="Left" Height="30" Margin="10,321,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Gateway 3 :" HorizontalAlignment="Left" Height="30" Margin="10,291,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port Node 3 :" HorizontalAlignment="Left" Height="30" Margin="10,351,0,0" VerticalAlignment="Top" Width="87" FontWeight="Bold"/>
                            <TextBox x:Name="DATAiSCSILIFIP3TextBox" KeyboardNavigation.TabIndex="42" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,259,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address..."/>
                            <TextBox x:Name="DATAiSCSILIFNETMASK3TextBox" KeyboardNavigation.TabIndex="44" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,321,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Netmask..."/>
                            <TextBox x:Name="DATAiSCSILIFGW3TextBox" KeyboardNavigation.TabIndex="43" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,290,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Gateway..."/>
                            <TextBox x:Name="DATAiSCSILIFPORT3TextBox" KeyboardNavigation.TabIndex="45" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,352,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port..."/>
                            <Label Content="IP Address 4 :" HorizontalAlignment="Left" Height="30" Margin="10,390,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Netmask 4 :" HorizontalAlignment="Left" Height="30" Margin="10,450,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Gateway 4 :" HorizontalAlignment="Left" Height="30" Margin="10,420,0,0" VerticalAlignment="Top" Width="80" FontWeight="Bold"/>
                            <Label Content="Port Node 4 :" HorizontalAlignment="Left" Height="30" Margin="10,480,0,0" VerticalAlignment="Top" Width="87" FontWeight="Bold"/>
                            <TextBox x:Name="DATAiSCSILIFIP4TextBox" KeyboardNavigation.TabIndex="46" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,388,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter IP Address..."/>
                            <TextBox x:Name="DATAiSCSILIFNETMASK4TextBox" KeyboardNavigation.TabIndex="48" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,450,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Netmask..."/>
                            <TextBox x:Name="DATAiSCSILIFGW4TextBox" KeyboardNavigation.TabIndex="47" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,419,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter Gateway..."/>
                            <TextBox x:Name="DATAiSCSILIFPORT4TextBox" KeyboardNavigation.TabIndex="49" Grid.ColumnSpan="2" HorizontalAlignment="Left" Height="30" Margin="102,481,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="277" Text="Enter 10GbE port..."/>
                        </Grid>
                    </Expander>
                </Grid>
            </Expander>
            <Button x:Name="SAVEConfigFileButton" Content="SAVE Configuration File" HorizontalAlignment="Left" Height="58" Margin="161,42,0,0" VerticalAlignment="Top" Width="208" FontWeight="Bold"/>
            <Button x:Name="ImportConfigFileButton" Content="Import Existing Configuration File" HorizontalAlignment="Left" Height="58" Margin="400,42,0,0" VerticalAlignment="Top" Width="202" FontWeight="Bold"/>
            <Image x:Name="NetappImage" HorizontalAlignment="Left" Height="77" Margin="42,42,0,0" VerticalAlignment="Top" Width="84"/>
        </Grid>
    </ScrollViewer >
</Window>


"@

$base64Image = "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"

$base64Icon = "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"

[void] [System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 


#Remocing all the XAML pieces from the visual studio XAMRAW.. 
[xml]$XMAL = $RawXAML -replace 'mc:Ignorable="d"','' -replace "x:",'' `
             -replace 'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" `
                       xmlns:d="http://schemas.microsoft.com/expression/blend/2008" `
                       xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" `
                       xmlns:local="clr-namespace:GenerationConfigFile" `', '' `
             -replace 'Class="GenerationConfigFile.MainWindow"', ''


#Read XAML 
$XAMLReader=(New-Object System.Xml.XmlNodeReader $XMAL)
try{
    $Window=[Windows.Markup.XamlReader]::Load($XAMLReader)
} catch {
    Throw "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
 
$XMAL.SelectNodes("//*[@Name]") | ForEach-Object {
    Set-Variable -Name "$($_.Name)" -Value $Window.FindName($_.Name)
}

$bitmapImage = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmapImage.BeginInit()
$bitmapImage.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64Image)
$bitmapImage.EndInit()
$bitmapImage.Freeze()


$bitmapIcon = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmapIcon.BeginInit()
$bitmapIcon.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64Icon)
$bitmapIcon.EndInit()
$bitmapIcon.Freeze()


# This is the big  pic
$NetappImage.Source = $bitmapImage

# This is the big  pic
$Window.Icon = $bitmapIcon


#Add Host Function....
$Initial = 0
Set-Variable -Name HostCounter -Value $Initial -Scope Global
Set-Variable -Name VMCounter -Value $Initial -Scope Global
Set-Variable -Name VMY -Value $Initial -Scope Global


Function HostCounterup(){

$Global:HostCounter = $Global:HostCounter+1

$Global:SVM_Y = 700 + 40*($Global:HostCounter-1)
$Global:VM_Y = 120 + 40*($Global:HostCounter-1)

}

Function VMCounterup(){

$Global:VMCounter = $Global:VMCounter+1

$Global:SVM_Y = 700 + 40*($Global:VMCounter-1)

}

Function HostCounterdown(){

$Global:HostCounter = $Global:HostCounter-1

$Global:SVM_Y = 700 + 40*($Global:HostCounter-1)
$Global:VM_Y = 120 + 40*($Global:HostCounter-1)

}

Function VMCounterdown(){

$Global:VMCounter = $Global:VMCounter-1
$Global:SVM_Y = 700 + 40*($Global:VMCounter-1)

}

$ADDHOSTBUTTON.Add_Click({

if($Global:HostCounter -ge 0){

HostCounterup

$VariableTextBox = 'ESXiSERVERTextBox'+$Global:HostCounter
$VariableLabel = 'ESXiSERVERLabel'+$Global:HostCounter

$NewTextBox = New-Object System.Windows.Controls.TextBox
$NewLabel = New-Object System.Windows.Controls.Label

New-Variable -Name $VariableTextBox -Value $NewTextBox
New-Variable -Name $VariableLabel -Value $NewLabel

$Top = 110 + 40*($Global:HostCounter-1)

(Get-Variable -Name $VariableTextBox -ValueOnly).Height = 36
(Get-Variable -Name $VariableTextBox -ValueOnly).Width = 281
(Get-Variable -Name $VariableTextBox -ValueOnly).Name = $VariableTextBox
(Get-Variable -Name $VariableTextBox -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableTextBox -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableTextBox -ValueOnly).Text = "Enter Hostname of the ESXi server "+$Global:HostCounter+" ..."
$ESXiServerExpanderGrid.AddChild((Get-Variable -Name $VariableTextBox -ValueOnly))
(Get-Variable -Name $VariableTextBox -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 204,$Top


(Get-Variable -Name $VariableLabel -ValueOnly).Height = 36
(Get-Variable -Name $VariableLabel -ValueOnly).Width = 123
(Get-Variable -Name $VariableLabel -ValueOnly).Name = $VariableLabel
(Get-Variable -Name $VariableLabel -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableLabel -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableLabel -ValueOnly).Content = "ESXi Hostname "+$Global:HostCounter+" :"
$ESXiServerExpanderGrid.AddChild((Get-Variable -Name $VariableLabel -ValueOnly))
(Get-Variable -Name $VariableLabel -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 81,$Top

$VMExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,$Global:VM_Y

if($VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,($Global:SVM_Y + 250 + 40*($Global:VMCounter-1))

}elseif(!$VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,$Global:SVM_Y

}

}

})

$DELETEHOSTButton.Add_Click({

if($Global:HostCounter -gt 0){

$VariableTextBox = 'ESXiSERVERTextBox'+$Global:HostCounter
$VariableLabel = 'ESXiSERVERLabel'+$Global:HostCounter

$DeleteTextBox = $ESXiServerExpanderGrid.Children | ?{$_.Name -eq $VariableTextBox }
$DeleteLabel = $ESXiServerExpanderGrid.Children | ?{$_.Name -eq $VariableLabel }

$ESXiServerExpanderGrid.Children.Remove($DeleteTextBox)
$ESXiServerExpanderGrid.Children.Remove($DeleteLabel)

HostCounterdown

$VMExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,$Global:VM_Y

if($VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,($Global:SVM_Y + 250 + 40*($Global:VMCounter-1))

}elseif(!$VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,$Global:SVM_Y

}

}

})

$ADDVMButton.Add_Click({

if($Global:VMCounter -ge 0){

VMCounterup

$VariableTextBox = 'VMIPAddressTextBox'+$Global:VMCounter
$VariableLabel = 'VMIPAddressLabel'+$Global:VMCounter

$NewTextBox = New-Object System.Windows.Controls.TextBox
$NewLabel = New-Object System.Windows.Controls.Label

New-Variable -Name $VariableTextBox -Value $NewTextBox
New-Variable -Name $VariableLabel -Value $NewLabel

$Top = 190 + 40*($Global:VMCounter-1)

(Get-Variable -Name $VariableTextBox -ValueOnly).Height = 36
(Get-Variable -Name $VariableTextBox -ValueOnly).Width = 281
(Get-Variable -Name $VariableTextBox -ValueOnly).Name = $VariableTextBox
(Get-Variable -Name $VariableTextBox -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableTextBox -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableTextBox -ValueOnly).Text = "Enter the IP Address for the VM "+$Global:VMCounter+" ..."
$VMExpanderGrid.AddChild((Get-Variable -Name $VariableTextBox -ValueOnly))
(Get-Variable -Name $VariableTextBox -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 204,$Top


(Get-Variable -Name $VariableLabel -ValueOnly).Height = 36
(Get-Variable -Name $VariableLabel -ValueOnly).Width = 123
(Get-Variable -Name $VariableLabel -ValueOnly).Name = $VariableLabel
(Get-Variable -Name $VariableLabel -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableLabel -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableLabel -ValueOnly).Content = "IP Address VM "+$Global:VMCounter+" :"
$VMExpanderGrid.AddChild((Get-Variable -Name $VariableLabel -ValueOnly))
(Get-Variable -Name $VariableLabel -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 81,$Top


if($ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,($Global:SVM_Y + 250 + 40*($Global:HostCounter-1))

}elseif(!$ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,($Global:SVM_Y + 100)

}

}


})

$DELETEVMButton.Add_Click({

if($Global:VMCounter -gt 0){

$VariableTextBox = 'VMIPAddressTextBox'+$Global:VMCounter
$VariableLabel = 'VMIPAddressLabel'+$Global:VMCounter

$DeleteTextBox = $VMExpanderGrid.Children | ?{$_.Name -eq $VariableTextBox }
$DeleteLabel = $VMExpanderGrid.Children | ?{$_.Name -eq $VariableLabel }

$VMExpanderGrid.Children.Remove($DeleteTextBox)
$VMExpanderGrid.Children.Remove($DeleteLabel)

VMCounterdown


if($ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,($Global:SVM_Y + 250 + 40*($Global:HostCounter-1))

}elseif(!$ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,($Global:SVM_Y +100)

}

}

})

$SAVEConfigFileButton.Add_Click({

$Global = @{}

$Global.Other = @{}

$Global.Other.Add('NumberofVolumesPerVM',$NumberofVolumesPerVMTextBox.Text)
$Global.Other.Add('VCenterIP',$VCenterIPTextBox.Text)
$Global.Other.Add('ClusterIP',$ClusterIPTextBox.Text)
$Global.Other.Add('NumberVMperhost',$NumberVMperhostTextBox.Text)
$Global.Other.Add('VolumeSize',$VolumeSizeTextBox.Text)
$Global.Other.Add('DSwitch',$DSwitchRadioButton.IsChecked)
$Global.Other.Add('PortGroupName',$PortGroupNameTextBox.Text)
$Global.Other.Add('NetworkName',$NetworkNameTextBox.Text)
$Global.Other.Add('FileSize',$FileSizeTextBox.Text)
$Global.Other.Add('Jumbo',$Jumbo.IsChecked)
$Global.Other.Add('NFS',$NFSRadioButton.IsChecked)
$Global.Other.Add('iSCSI',$iSCSIRadioButton.IsChecked)
$Global.Other.Add('FC',$FCRadioButton.IsChecked)
$Global.Other.Add('LunID',$LunIDTextBox.Text)
$Global.Other.Add('Pathvdbench',$PathvdbenchTextBox.Text)
$Global.Other.Add('PathOVA',$PathOVATextBox.Text)

$Global.SVM = @{}

$Global.SVM.Add('Name',$SVMNameTextBox.Text)

$Global.VMsLIF = @{}
$Global.VMsLIF.lif0 = @{}

$Global.VMsLIF.lif0.Add('Name',$SVMNameTextBox.Text)
$Global.VMsLIF.lif0.Add('IP',$NFSLIFIPTextBox.Text)
$Global.VMsLIF.lif0.Add('Gateway',$NFSLIFGWTextBox.Text)
$Global.VMsLIF.lif0.Add('Netmask',$NFSLIFNETMASKTextBox.Text)
$Global.VMsLIF.lif0.Add('Port',$NFSLIFPORTTextBox.Text)

$Global.VMsLIF.lif1 = @{}

$Global.VMsLIF.lif1.Add('Name',$SVMNameTextBox.Text+"_FC")
$Global.VMsLIF.lif1.Add('Port',$FCLIFPORTDATASTORETextBox.Text)

$Global.LIFSNFS = @{}
$Global.LIFSNFS.lif1 = @{}
$Global.LIFSNFS.lif2 = @{}
$Global.LIFSNFS.lif3 = @{}
$Global.LIFSNFS.lif4 = @{}

$Global.LIFSNFS.lif1.Add('Name',$SVMNameTextBox.Text+"_nfs_node01-lif-1")
$Global.LIFSNFS.lif1.Add('IP',$DATANFSLIFIP1TextBox.Text)
$Global.LIFSNFS.lif1.Add('Gateway',$DATANFSLIFGWTextBox.Text)
$Global.LIFSNFS.lif1.Add('Netmask',$DATANFSLIFNETMASKTextBox.Text)
$Global.LIFSNFS.lif1.Add('Port',$DATANFSLIFPORT1TextBox.Text)

$Global.LIFSNFS.lif2.Add('Name',$SVMNameTextBox.Text+"_nfs_node01-lif-2")
$Global.LIFSNFS.lif2.Add('IP',$DATANFSLIFIP2TextBox.Text)
$Global.LIFSNFS.lif2.Add('Gateway',$DATANFSLIFGWTextBox.Text)
$Global.LIFSNFS.lif2.Add('Netmask',$DATANFSLIFNETMASKTextBox.Text)
$Global.LIFSNFS.lif2.Add('Port',$DATANFSLIFPORT2TextBox.Text)

$Global.LIFSNFS.lif3.Add('Name',$SVMNameTextBox.Text+"_nfs_node02-lif-1")
$Global.LIFSNFS.lif3.Add('IP',$DATANFSLIFIP3TextBox.Text)
$Global.LIFSNFS.lif3.Add('Gateway',$DATANFSLIFGWTextBox.Text)
$Global.LIFSNFS.lif3.Add('Netmask',$DATANFSLIFNETMASKTextBox.Text)
$Global.LIFSNFS.lif3.Add('Port',$DATANFSLIFPORT3TextBox.Text)

$Global.LIFSNFS.lif4.Add('Name',$SVMNameTextBox.Text+"_nfs_node02-lif-2")
$Global.LIFSNFS.lif4.Add('IP',$DATANFSLIFIP4TextBox.Text)
$Global.LIFSNFS.lif4.Add('Gateway',$DATANFSLIFGWTextBox.Text)
$Global.LIFSNFS.lif4.Add('Netmask',$DATANFSLIFNETMASKTextBox.Text)
$Global.LIFSNFS.lif4.Add('Port',$DATANFSLIFPORT4TextBox.Text)

$Global.LIFSiSCSI = @{}

$Global.LIFSiSCSI.lif5 = @{}
$Global.LIFSiSCSI.lif6 = @{}
$Global.LIFSiSCSI.lif7 = @{}
$Global.LIFSiSCSI.lif8 = @{}

$Global.LIFSiSCSI.lif5.Add('Name',$SVMNameTextBox.Text+"_iscsi_node01-lif-1")
$Global.LIFSiSCSI.lif5.Add('IP',$DATAiSCSILIFIP1TextBox.Text)
$Global.LIFSiSCSI.lif5.Add('Gateway',$DATAiSCSILIFGW1TextBox.Text)
$Global.LIFSiSCSI.lif5.Add('Netmask',$DATAiSCSILIFNETMASK1TextBox.Text)
$Global.LIFSiSCSI.lif5.Add('Port',$DATAiSCSILIFPORT1TextBox.Text)

$Global.LIFSiSCSI.lif6.Add('Name',$SVMNameTextBox.Text+"_iscsi_node01-lif-2")
$Global.LIFSiSCSI.lif6.Add('IP',$DATAiSCSILIFIP2TextBox.Text)
$Global.LIFSiSCSI.lif6.Add('Gateway',$DATAiSCSILIFGW2TextBox.Text)
$Global.LIFSiSCSI.lif6.Add('Netmask',$DATAiSCSILIFNETMASK2TextBox.Text)
$Global.LIFSiSCSI.lif6.Add('Port',$DATAiSCSILIFPORT2TextBox.Text)

$Global.LIFSiSCSI.lif7.Add('Name',$SVMNameTextBox.Text+"_iscsi_node02-lif-1")
$Global.LIFSiSCSI.lif7.Add('IP',$DATAiSCSILIFIP3TextBox.Text)
$Global.LIFSiSCSI.lif7.Add('Gateway',$DATAiSCSILIFGW3TextBox.Text)
$Global.LIFSiSCSI.lif7.Add('Netmask',$DATAiSCSILIFNETMASK3TextBox.Text)
$Global.LIFSiSCSI.lif7.Add('Port',$DATAiSCSILIFPORT3TextBox.Text)

$Global.LIFSiSCSI.lif8.Add('Name',$SVMNameTextBox.Text+"_iscsi_node02-lif-2")
$Global.LIFSiSCSI.lif8.Add('IP',$DATAiSCSILIFIP4TextBox.Text)
$Global.LIFSiSCSI.lif8.Add('Gateway',$DATAiSCSILIFGW4TextBox.Text)
$Global.LIFSiSCSI.lif8.Add('Netmask',$DATAiSCSILIFNETMASK4TextBox.Text)
$Global.LIFSiSCSI.lif8.Add('Port',$DATAiSCSILIFPORT4TextBox.Text)


$Global.LIFSFC = @{}

$Global.LIFSFC.lif9 = @{}
$Global.LIFSFC.lif10 = @{}
$Global.LIFSFC.lif11 = @{}
$Global.LIFSFC.lif12 = @{}

$Global.LIFSFC.lif9.Add('Name',$SVMNameTextBox.Text+"_FC_node01-lif-1")
$Global.LIFSFC.lif9.Add('Port',$DATAFCLIF1PORTNODE1TextBox.Text)
$Global.LIFSFC.lif10.Add('Name',$SVMNameTextBox.Text+"_FC_node01-lif-2")
$Global.LIFSFC.lif10.Add('Port',$DATAFCLIF2PORTNODE1TextBox.Text)
$Global.LIFSFC.lif11.Add('Name',$SVMNameTextBox.Text+"_FC_node02-lif-1")
$Global.LIFSFC.lif11.Add('Port',$DATAFCLIF1PORTNODE2TextBox.Text)
$Global.LIFSFC.lif12.Add('Name',$SVMNameTextBox.Text+"_FC_node02-lif-2")
$Global.LIFSFC.lif12.Add('Port',$DATAFCLIF2PORTNODE2TextBox.Text)


$Global.VMs = @{}
$Global.VMs.VM00 = @{}

if($NFSRadioButton.IsChecked){
$SVM_Prefix = "NFS"
}elseif($iSCSIRadioButton.IsChecked){
$SVM_Prefix = "iSCSI"
}elseif($FCRadioButton.IsChecked){
$SVM_Prefix = "FCP"
}

$Global.VMs.VM00.Add('Name',$SVMNameTextBox.Text+"_"+$SVM_Prefix+"_00")
$Global.VMs.VM00.Add('IP',$VMIPAddressTextBox0.Text)
$Global.VMs.VM00.Add('Gateway',$VMGatewayTextBox.Text)
$Global.VMs.VM00.Add('Netmask',$VMNetmaskTextBox.Text)

for($Count = 1 ; $Count -le $Global:VMCounter ; $Count++){

$NameVariableVM = 'VM0'+$Count

$Global.VMs.$NameVariableVM = @{} 

$Global.VMs.$NameVariableVM.Add('Name',$SVMNameTextBox.Text+"_"+$SVM_Prefix+"_0"+$Count)

$NameVariableIP = 'VMIPAddressTextBox'+$Count
$NameVariableIPText = $VMExpanderGrid.Children | ?{$_.Name -eq $NameVariableIP }

$Global.VMs.$NameVariableVM.Add('IP',$NameVariableIPText.Text)

}


$Global.Hosts = @{}

$Global.Hosts.Host00 = @{}

$Global.Hosts.Host00.Add('Name',$ESXiSERVERTextBox0.Text)

for($Count = 1 ; $Count -le $Global:HostCounter ; $Count++){

$NameVariableHost = 'Host0'+$Count

$Global.Hosts.$NameVariableHost = @{}

$NameVariableIP = 'ESXiSERVERTextBox'+$Count
$NameVariableIPText = $ESXiServerExpanderGrid.Children | ?{$_.Name -eq $NameVariableIP }
$Global.Hosts.$NameVariableHost.Add('Name',$NameVariableIPText.Text)


}

#Saving the configuration File. 

$SaveFileDialog = New-Object windows.forms.savefiledialog   
$SaveFileDialog.initialDirectory = [System.IO.Directory]::GetCurrentDirectory()   
$SaveFileDialog.title = "Selected Location to Save the config file"   
$SaveFileDialog.filter = "Powershell|*.ps1|PublishSettings Files|*.publishsettings|All Files|*.*" 
$SaveFileDialog.ShowHelp = $True   
$result = $SaveFileDialog.ShowDialog()    
$result 
    if($result -eq "OK")    {    
            Write-Host "Location to Save the config file :" -ForegroundColor Green  
            $SaveFileDialog.filename   
        } 
        else { Write-Host "File Save Dialog Cancelled!" -ForegroundColor Yellow} 


$Global | ConvertTo-JSON | Set-Content -Path $SaveFileDialog.filename

})

$ImportConfigFileButton.Add_Click({

$SVMConfigurationExpander.IsExpanded = $false
$VMWareConfigurationExpander.IsExpanded = $false
$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

$InputConfigFile = Get-FileName ".\" ps1

# $InputConfigFile is an array
# $InputConfigFile[0] is the Configuratiton path.

$ConfigFilePath = $InputConfigFile[0]

if($ConfigFilePath){

$GlobalObject = Get-Content -Path $ConfigFilePath -Raw -ErrorAction SilentlyContinue | ConvertFrom-JSON

$NumberofVolumesPerVMTextBox.Text =  $GlobalObject.Other.NumberofVolumesPerVM.Trim()
$VCenterIPTextBox.Text = $GlobalObject.Other.VCenterIP.Trim()
$ClusterIPTextBox.Text = $GlobalObject.Other.ClusterIP.Trim()
$NumberVMperhostTextBox.Text = $GlobalObject.Other.NumberVMperhost.Trim()
$VolumeSizeTextBox.Text = $GlobalObject.Other.VolumeSize.Trim()
$DSwitchRadioButton.IsChecked = $GlobalObject.Other.DSwitch
$VSWITCHRadioButton.ISChecked = !$DSwitchRadioButton.IsChecked
$PortGroupNameTextBox.Text = $GlobalObject.Other.PortGroupName.Trim()
$NetworkNameTextBox.Text = $GlobalObject.Other.NetworkName.Trim()
$FileSizeTextBox.Text = $GlobalObject.Other.FileSize.Trim()
$Jumbo.IsChecked = $GlobalObject.Other.Jumbo
$MTU1500RadioButton.ISChecked = !$Jumbo.IsChecked
$NFSRadioButton.IsChecked = $GlobalObject.Other.NFS
$iSCSIRadioButton.IsChecked = $GlobalObject.Other.iSCSI
$FCRadioButton.IsChecked = $GlobalObject.Other.FC
$LunIDTextBox.Text = $GlobalObject.Other.LunID.Trim()
$PathvdbenchTextBox.Text = $GlobalObject.Other.Pathvdbench.Trim()
$PathOVATextBox.Text = $GlobalObject.Other.PathOVA.Trim()



$SVMNameTextBox.Text = $GlobalObject.SVM.Name.Trim()


$NFSLIFIPTextBox.Text = $GlobalObject.VMsLIF.lif0.IP.Trim()
$NFSLIFGWTextBox.Text = $GlobalObject.VMsLIF.lif0.Gateway.Trim()
$NFSLIFNETMASKTextBox.Text = $GlobalObject.VMsLIF.lif0.Netmask.Trim()
$NFSLIFPORTTextBox.Text = $GlobalObject.VMsLIF.lif0.Port.Trim()


$FCLIFPORTDATASTORETextBox.Text = $GlobalObject.VMsLIF.lif1.Port.Trim()

$DATANFSLIFIP1TextBox.Text = $GlobalObject.LIFSNFS.lif1.IP.Trim()
$DATANFSLIFGWTextBox.Text = $GlobalObject.LIFSNFS.lif1.Gateway.Trim()
$DATANFSLIFNETMASKTextBox.Text = $GlobalObject.LIFSNFS.lif1.Netmask.Trim()
$DATANFSLIFPORT1TextBox.Text = $GlobalObject.LIFSNFS.lif1.Port.Trim()

$DATANFSLIFIP2TextBox.Text = $GlobalObject.LIFSNFS.lif2.IP.Trim()
$DATANFSLIFGWTextBox.Text = $GlobalObject.LIFSNFS.lif2.Gateway.Trim()
$DATANFSLIFNETMASKTextBox.Text = $GlobalObject.LIFSNFS.lif2.Netmask.Trim()
$DATANFSLIFPORT2TextBox.Text = $GlobalObject.LIFSNFS.lif2.Port.Trim()

$DATANFSLIFIP3TextBox.Text = $GlobalObject.LIFSNFS.lif3.IP.Trim()
$DATANFSLIFGWTextBox.Text = $GlobalObject.LIFSNFS.lif3.Gateway.Trim()
$DATANFSLIFNETMASKTextBox.Text = $GlobalObject.LIFSNFS.lif3.Netmask.Trim()
$DATANFSLIFPORT3TextBox.Text = $GlobalObject.LIFSNFS.lif3.Port.Trim()

$DATANFSLIFIP4TextBox.Text = $GlobalObject.LIFSNFS.lif4.IP.Trim()
$DATANFSLIFGWTextBox.Text = $GlobalObject.LIFSNFS.lif4.Gateway.Trim()
$DATANFSLIFNETMASKTextBox.Text = $GlobalObject.LIFSNFS.lif4.Netmask.Trim()
$DATANFSLIFPORT4TextBox.Text = $GlobalObject.LIFSNFS.lif4.Port.Trim()


$DATAiSCSILIFIP1TextBox.Text = $GlobalObject.LIFSiSCSI.lif5.IP.Trim()
$DATAiSCSILIFGW1TextBox.Text = $GlobalObject.LIFSiSCSI.lif5.Gateway.Trim()
$DATAiSCSILIFNETMASK1TextBox.Text = $GlobalObject.LIFSiSCSI.lif5.Netmask.Trim()
$DATAiSCSILIFPORT1TextBox.Text = $GlobalObject.LIFSiSCSI.lif5.Port.Trim()

$DATAiSCSILIFIP2TextBox.Text = $GlobalObject.LIFSiSCSI.lif6.IP.Trim()
$DATAiSCSILIFGW2TextBox.Text = $GlobalObject.LIFSiSCSI.lif6.Gateway.Trim()
$DATAiSCSILIFNETMASK2TextBox.Text = $GlobalObject.LIFSiSCSI.lif6.Netmask.Trim()
$DATAiSCSILIFPORT2TextBox.Text = $GlobalObject.LIFSiSCSI.lif6.Port.Trim()

$DATAiSCSILIFIP3TextBox.Text = $GlobalObject.LIFSiSCSI.lif7.IP.Trim()
$DATAiSCSILIFGW3TextBox.Text = $GlobalObject.LIFSiSCSI.lif7.Gateway.Trim()
$DATAiSCSILIFNETMASK3TextBox.Text = $GlobalObject.LIFSiSCSI.lif7.Netmask.Trim()
$DATAiSCSILIFPORT3TextBox.Text = $GlobalObject.LIFSiSCSI.lif7.Port.Trim()

$DATAiSCSILIFIP4TextBox.Text = $GlobalObject.LIFSiSCSI.lif8.IP.Trim()
$DATAiSCSILIFGW4TextBox.Text = $GlobalObject.LIFSiSCSI.lif8.Gateway.Trim()
$DATAiSCSILIFNETMASK4TextBox.Text = $GlobalObject.LIFSiSCSI.lif8.Netmask.Trim()
$DATAiSCSILIFPORT4TextBox.Text = $GlobalObject.LIFSiSCSI.lif8.Port.Trim()


$DATAFCLIF1PORTNODE1TextBox.Text = $GlobalObject.LIFSFC.lif9.Port.Trim()
$DATAFCLIF2PORTNODE1TextBox.Text = $GlobalObject.LIFSFC.lif10.Port.Trim()
$DATAFCLIF1PORTNODE2TextBox.Text = $GlobalObject.LIFSFC.lif11.Port.Trim()
$DATAFCLIF2PORTNODE2TextBox.Text = $GlobalObject.LIFSFC.lif12.Port.Trim()

$VMIPAddressTextBox0.Text = $GlobalObject.VMs.VM00.IP.Trim()
$VMGatewayTextBox.Text = $GlobalObject.VMs.VM00.Gateway.Trim()
$VMNetmaskTextBox.Text = $GlobalObject.VMs.VM00.Netmask.Trim()

$Initial = 0
Set-Variable -Name HostCounter -Value $Initial -Scope Global
Set-Variable -Name VMCounter -Value $Initial -Scope Global
Set-Variable -Name VMY -Value $Initial -Scope Global

$VMs = $GlobalObject | select -Expand VMs


foreach($item in $VMs | Get-Member | ?{$_.MemberType -eq "NoteProperty"}){


if($item.Name -ne "VM00"){

$ItemName = $item.Name

VMCounterup

$VariableTextBox = 'VMIPAddressTextBox'+$Global:VMCounter
$VariableLabel = 'VMIPAddressLabel'+$Global:VMCounter

$NewTextBox = New-Object System.Windows.Controls.TextBox
$NewLabel = New-Object System.Windows.Controls.Label

New-Variable -Name $VariableTextBox -Value $NewTextBox
New-Variable -Name $VariableLabel -Value $NewLabel

$Top = 190 + 40*($Global:VMCounter-1)

(Get-Variable -Name $VariableTextBox -ValueOnly).Height = 36
(Get-Variable -Name $VariableTextBox -ValueOnly).Width = 281
(Get-Variable -Name $VariableTextBox -ValueOnly).Name = $VariableTextBox
(Get-Variable -Name $VariableTextBox -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableTextBox -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableTextBox -ValueOnly).Text = $GlobalObject.VMs.$ItemName.IP.Trim()
$VMExpanderGrid.AddChild((Get-Variable -Name $VariableTextBox -ValueOnly))
(Get-Variable -Name $VariableTextBox -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 204,$Top
(Get-Variable -Name $VariableTextBox -ValueOnly).Tag = 'ConfigFile'

(Get-Variable -Name $VariableLabel -ValueOnly).Height = 36
(Get-Variable -Name $VariableLabel -ValueOnly).Width = 123
(Get-Variable -Name $VariableLabel -ValueOnly).Name = $VariableLabel
(Get-Variable -Name $VariableLabel -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableLabel -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableLabel -ValueOnly).Content = "IP Address VM "+$Global:VMCounter+" :"
$VMExpanderGrid.AddChild((Get-Variable -Name $VariableLabel -ValueOnly))
(Get-Variable -Name $VariableLabel -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 81,$Top

}


}


$ESXiSERVERTextBox0.Text = $GlobalObject.Hosts.Host00.Name.Trim()

$Hosts = $GlobalObject | select -Expand Hosts


foreach($item in $Hosts | Get-Member | ?{$_.MemberType -eq "NoteProperty"}){

if($item.Name -ne "Host00"){

$ItemName = $item.Name

HostCounterup

$VariableTextBox = 'ESXiSERVERTextBox'+$Global:HostCounter
$VariableLabel = 'ESXiSERVERLabel'+$Global:HostCounter

$NewTextBox = New-Object System.Windows.Controls.TextBox
$NewLabel = New-Object System.Windows.Controls.Label

New-Variable -Name $VariableTextBox -Value $NewTextBox
New-Variable -Name $VariableLabel -Value $NewLabel

$Top = 110 + 40*($Global:HostCounter-1)

(Get-Variable -Name $VariableTextBox -ValueOnly).Height = 36
(Get-Variable -Name $VariableTextBox -ValueOnly).Width = 281
(Get-Variable -Name $VariableTextBox -ValueOnly).Name = $VariableTextBox
(Get-Variable -Name $VariableTextBox -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableTextBox -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableTextBox -ValueOnly).Text = $GlobalObject.Hosts.$ItemName.Name.Trim()
$ESXiServerExpanderGrid.AddChild((Get-Variable -Name $VariableTextBox -ValueOnly))
(Get-Variable -Name $VariableTextBox -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 204,$Top
(Get-Variable -Name $VariableTextBox -ValueOnly).Tag = 'ConfigFile'

(Get-Variable -Name $VariableLabel -ValueOnly).Height = 36
(Get-Variable -Name $VariableLabel -ValueOnly).Width = 123
(Get-Variable -Name $VariableLabel -ValueOnly).Name = $VariableLabel
(Get-Variable -Name $VariableLabel -ValueOnly).HorizontalAlignment = "Left"
(Get-Variable -Name $VariableLabel -ValueOnly).VerticalAlignment = "Top"
(Get-Variable -Name $VariableLabel -ValueOnly).Content = "ESXi Hostname "+$Global:HostCounter+" :"
$ESXiServerExpanderGrid.AddChild((Get-Variable -Name $VariableLabel -ValueOnly))
(Get-Variable -Name $VariableLabel -ValueOnly).RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 81,$Top

$VMExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

}

}

$NumberofVolumesPerVMTextBox.Tag = 'ConfigFile'
$VCenterIPTextBox.Tag = 'ConfigFile'
$ClusterIPTextBox.Tag = 'ConfigFile'
$VolumeSizeTextBox.Tag = 'ConfigFile'
$PortGroupNameTextBox.Tag = 'ConfigFile'
$NetworkNameTextBox.Tag = 'ConfigFile'
$FileSizeTextBox.Tag = 'ConfigFile'
$LunIDTextBox.Tag = 'ConfigFile'
$PathvdbenchTextBox.Tag = 'ConfigFile'
$PathOVATextBox.Tag = 'ConfigFile'
$NumberVMperhostTextBox.Tag = 'ConfigFile'

$SVMNameTextBox.Tag = 'ConfigFile'
$NFSLIFIPTextBox.Tag = 'ConfigFile'
$NFSLIFGWTextBox.Tag = 'ConfigFile'
$NFSLIFNETMASKTextBox.Tag = 'ConfigFile'
$NFSLIFPORTTextBox.Tag = 'ConfigFile'


$FCLIFPORTDATASTORETextBox.Tag = 'ConfigFile'

$DATANFSLIFIP1TextBox.Tag = 'ConfigFile'
$DATANFSLIFGWTextBox.Tag = 'ConfigFile'
$DATANFSLIFNETMASKTextBox.Tag = 'ConfigFile'
$DATANFSLIFPORT1TextBox.Tag = 'ConfigFile'

$DATANFSLIFIP2TextBox.Tag = 'ConfigFile'
$DATANFSLIFPORT2TextBox.Tag = 'ConfigFile'

$DATANFSLIFIP3TextBox.Tag = 'ConfigFile'
$DATANFSLIFPORT3TextBox.Tag = 'ConfigFile'

$DATANFSLIFIP4TextBox.Tag = 'ConfigFile'
$DATANFSLIFPORT4TextBox.Tag = 'ConfigFile'

$DATAiSCSILIFIP1TextBox.Tag = 'ConfigFile' 
$DATAiSCSILIFGW1TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFNETMASK1TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFPORT1TextBox.Tag = 'ConfigFile'

$DATAiSCSILIFIP2TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFGW2TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFNETMASK2TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFPORT2TextBox.Tag = 'ConfigFile'

$DATAiSCSILIFIP3TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFGW3TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFNETMASK3TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFPORT3TextBox.Tag = 'ConfigFile'

$DATAiSCSILIFIP4TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFGW4TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFNETMASK4TextBox.Tag = 'ConfigFile'
$DATAiSCSILIFPORT4TextBox.Tag = 'ConfigFile'


$DATAFCLIF1PORTNODE1TextBox.Tag = 'ConfigFile'
$DATAFCLIF2PORTNODE1TextBox.Tag = 'ConfigFile'
$DATAFCLIF1PORTNODE2TextBox.Tag = 'ConfigFile'
$DATAFCLIF2PORTNODE2TextBox.Tag = 'ConfigFile'

$VMIPAddressTextBox0.Tag = 'ConfigFile'
$VMGatewayTextBox.Tag = 'ConfigFile'
$VMNetmaskTextBox.Tag = 'ConfigFile'

$ESXiSERVERTextBox0.Tag = 'ConfigFile'


}

})


#Clear all the Default Text in the Text Boxes....

$PathOVATextBox.Add_GotFocus({
  if($PathOVATextBox.Tag -eq $null) { # clear the text box
    $PathOVATextBox.Text = ' '
    $PathOVATextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$PathvdbenchTextBox.Add_GotFocus({
  if($PathvdbenchTextBox.Tag -eq $null) { # clear the text box
    $PathvdbenchTextBox.Text = ' '
    $PathvdbenchTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$NumberofVolumesPerVMTextBox.Add_GotFocus({
  if($NumberofVolumesPerVMTextBox.Tag -eq $null) { # clear the text box
    $NumberofVolumesPerVMTextBox.Text = ' '
    $NumberofVolumesPerVMTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$VCenterIPTextBox.Add_GotFocus({
  if($VCenterIPTextBox.Tag -eq $null) { # clear the text box
    $VCenterIPTextBox.Text = ' '
    $VCenterIPTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$ClusterIPTextBox.Add_GotFocus({
  if($ClusterIPTextBox.Tag -eq $null) { # clear the text box
    $ClusterIPTextBox.Text = ' '
    $ClusterIPTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$NumberVMperhostTextBox.Add_GotFocus({
  if($NumberVMperhostTextBox.Tag -eq $null) { # clear the text box
    $NumberVMperhostTextBox.Text = ' '
    $NumberVMperhostTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$VolumeSizeTextBox.Add_GotFocus({
  if($VolumeSizeTextBox.Tag -eq $null) { # clear the text box
    $VolumeSizeTextBox.Text = ' '
    $VolumeSizeTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$FileSizeTextBox.Add_GotFocus({
  if($FileSizeTextBox.Tag -eq $null) { # clear the text box
    $FileSizeTextBox.Text = ' '
    $FileSizeTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$NetworkNameTextBox.Add_GotFocus({
  if($NetworkNameTextBox.Tag -eq $null) { # clear the text box
    $NetworkNameTextBox.Text = ' '
    $NetworkNameTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$PortGroupNameTextBox.Add_GotFocus({
  if($PortGroupNameTextBox.Tag -eq $null) { # clear the text box
    $PortGroupNameTextBox.Text = ' '
    $PortGroupNameTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$LunIDTextBox.Add_GotFocus({
  if($LunIDTextBox.Tag -eq $null) { # clear the text box
    $LunIDTextBox.Text = ' '
    $LunIDTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$SVMNameTextBox.Add_GotFocus({
  if($SVMNameTextBox.Tag -eq $null) { # clear the text box
    $SVMNameTextBox.Text = ' '
    $SVMNameTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})


##############################################
$NFSLIFIPTextBox.Add_GotFocus({
  if($NFSLIFIPTextBox.Tag -eq $null) { # clear the text box
    $NFSLIFIPTextBox.Text = ' '
    $NFSLIFIPTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$NFSLIFNETMASKTextBox.Add_GotFocus({
  if($NFSLIFNETMASKTextBox.Tag -eq $null) { # clear the text box
    $NFSLIFNETMASKTextBox.Text = ' '
    $NFSLIFNETMASKTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$NFSLIFGWTextBox.Add_GotFocus({
  if($NFSLIFGWTextBox.Tag -eq $null) { # clear the text box
    $NFSLIFGWTextBox.Text = ' '
    $NFSLIFGWTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$NFSLIFPORTTextBox.Add_GotFocus({
  if($NFSLIFPORTTextBox.Tag -eq $null) { # clear the text box
    $NFSLIFPORTTextBox.Text = ' '
    $NFSLIFPORTTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$FCLIFPORTDATASTORETextBox.Add_GotFocus({
  if($FCLIFPORTDATASTORETextBox.Tag -eq $null) { # clear the text box
    $FCLIFPORTDATASTORETextBox.Text = ' '
    $FCLIFPORTDATASTORETextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAFCLIF1PORTNODE1TextBox.Add_GotFocus({
  if($DATAFCLIF1PORTNODE1TextBox.Tag -eq $null) { # clear the text box
    $DATAFCLIF1PORTNODE1TextBox.Text = ' '
    $DATAFCLIF1PORTNODE1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAFCLIF2PORTNODE1TextBox.Add_GotFocus({
  if($DATAFCLIF2PORTNODE1TextBox.Tag -eq $null) { # clear the text box
    $DATAFCLIF2PORTNODE1TextBox.Text = ' '
    $DATAFCLIF2PORTNODE1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAFCLIF1PORTNODE2TextBox.Add_GotFocus({
  if($DATAFCLIF1PORTNODE2TextBox.Tag -eq $null) { # clear the text box
    $DATAFCLIF1PORTNODE2TextBox.Text = ' '
    $DATAFCLIF1PORTNODE2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAFCLIF2PORTNODE2TextBox.Add_GotFocus({
  if($DATAFCLIF2PORTNODE2TextBox.Tag -eq $null) { # clear the text box
    $DATAFCLIF2PORTNODE2TextBox.Text = ' '
    $DATAFCLIF2PORTNODE2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFGWTextBox.Add_GotFocus({
  if($DATANFSLIFGWTextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFGWTextBox.Text = ' '
    $DATANFSLIFGWTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFNETMASKTextBox.Add_GotFocus({
  if($DATANFSLIFNETMASKTextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFNETMASKTextBox.Text = ' '
    $DATANFSLIFNETMASKTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFIP1TextBox.Add_GotFocus({
  if($DATANFSLIFIP1TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFIP1TextBox.Text = ' '
    $DATANFSLIFIP1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFPORT1TextBox.Add_GotFocus({
  if($DATANFSLIFPORT1TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFPORT1TextBox.Text = ' '
    $DATANFSLIFPORT1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFIP2TextBox.Add_GotFocus({
  if($DATANFSLIFIP2TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFIP2TextBox.Text = ' '
    $DATANFSLIFIP2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFPORT2TextBox.Add_GotFocus({
  if($DATANFSLIFPORT2TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFPORT2TextBox.Text = ' '
    $DATANFSLIFPORT2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFIP3TextBox.Add_GotFocus({
  if($DATANFSLIFIP3TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFIP3TextBox.Text = ' '
    $DATANFSLIFIP3TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFPORT3TextBox.Add_GotFocus({
  if($DATANFSLIFPORT3TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFPORT3TextBox.Text = ' '
    $DATANFSLIFPORT3TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFIP4TextBox.Add_GotFocus({
  if($DATANFSLIFIP4TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFIP4TextBox.Text = ' '
    $DATANFSLIFIP4TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATANFSLIFPORT4TextBox.Add_GotFocus({
  if($DATANFSLIFPORT4TextBox.Tag -eq $null) { # clear the text box
    $DATANFSLIFPORT4TextBox.Text = ' '
    $DATANFSLIFPORT4TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFIP1TextBox.Add_GotFocus({
  if($DATAiSCSILIFIP1TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFIP1TextBox.Text = ' '
    $DATAiSCSILIFIP1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFGW1TextBox.Add_GotFocus({
  if($DATAiSCSILIFGW1TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFGW1TextBox.Text = ' '
    $DATAiSCSILIFGW1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFNETMASK1TextBox.Add_GotFocus({
  if($DATAiSCSILIFNETMASK1TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFNETMASK1TextBox.Text = ' '
    $DATAiSCSILIFNETMASK1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFPORT1TextBox.Add_GotFocus({
  if($DATAiSCSILIFPORT1TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFPORT1TextBox.Text = ' '
    $DATAiSCSILIFPORT1TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFIP2TextBox.Add_GotFocus({
  if($DATAiSCSILIFIP2TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFIP2TextBox.Text = ' '
    $DATAiSCSILIFIP2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFGW2TextBox.Add_GotFocus({
  if($DATAiSCSILIFGW2TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFGW2TextBox.Text = ' '
    $DATAiSCSILIFGW2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFNETMASK2TextBox.Add_GotFocus({
  if($DATAiSCSILIFNETMASK2TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFNETMASK2TextBox.Text = ' '
    $DATAiSCSILIFNETMASK2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFPORT2TextBox.Add_GotFocus({
  if($DATAiSCSILIFPORT2TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFPORT2TextBox.Text = ' '
    $DATAiSCSILIFPORT2TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFIP3TextBox.Add_GotFocus({
  if($DATAiSCSILIFIP3TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFIP3TextBox.Text = ' '
    $DATAiSCSILIFIP3TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFGW3TextBox.Add_GotFocus({
  if($DATAiSCSILIFGW3TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFGW3TextBox.Text = ' '
    $DATAiSCSILIFGW3TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFNETMASK3TextBox.Add_GotFocus({
  if($DATAiSCSILIFNETMASK3TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFNETMASK3TextBox.Text = ' '
    $DATAiSCSILIFNETMASK3TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFPORT3TextBox.Add_GotFocus({
  if($DATAiSCSILIFPORT3TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFPORT3TextBox.Text = ' '
    $DATAiSCSILIFPORT3TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFIP4TextBox.Add_GotFocus({
  if($DATAiSCSILIFIP4TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFIP4TextBox.Text = ' '
    $DATAiSCSILIFIP4TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFGW4TextBox.Add_GotFocus({
  if($DATAiSCSILIFGW4TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFGW4TextBox.Text = ' '
    $DATAiSCSILIFGW4TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFNETMASK4TextBox.Add_GotFocus({
  if($DATAiSCSILIFNETMASK4TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFNETMASK4TextBox.Text = ' '
    $DATAiSCSILIFNETMASK4TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$DATAiSCSILIFPORT4TextBox.Add_GotFocus({
  if($DATAiSCSILIFPORT4TextBox.Tag -eq $null) { # clear the text box
    $DATAiSCSILIFPORT4TextBox.Text = ' '
    $DATAiSCSILIFPORT4TextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$VMIPAddressTextBox0.Add_GotFocus({
  if($VMIPAddressTextBox0.Tag -eq $null) { # clear the text box
    $VMIPAddressTextBox0.Text = ' '
    $VMIPAddressTextBox0.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$VMGatewayTextBox.Add_GotFocus({
  if($VMGatewayTextBox.Tag -eq $null) { # clear the text box
    $VMGatewayTextBox.Text = ' '
    $VMGatewayTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$VMNetmaskTextBox.Add_GotFocus({
  if($VMNetmaskTextBox.Tag -eq $null) { # clear the text box
    $VMNetmaskTextBox.Text = ' '
    $VMNetmaskTextBox.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$ESXiSERVERTextBox0.Add_GotFocus({
  if($ESXiSERVERTextBox0.Tag -eq $null) { # clear the text box
    $ESXiSERVERTextBox0.Text = ' '
    $ESXiSERVERTextBox0.Tag = 'cleared' # use any text you want to indicate that its cleared
  }
})

$SVMConfigurationExpander.IsExpanded = $false
$VMWareConfigurationExpander.IsExpanded = $false
$NFSIPCONFIGURATIONExpander.IsExpanded = $false
$FCDATASTORECONFIGURATIONExpander.IsExpanded = $false
$DATANFSIPCONFIGURATIONExpander.IsExpanded = $false
$iSCSIIPCONFIGURATIONExpander.IsExpanded = $false

#Expander VMWare Configuration when is closing...
$VMWareConfigurationExpander.Add_Collapsed({

#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is closing.. 

if($VMWareConfigurationExpander.IsExpanded -and $VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 75 + 40*($Global:VMCounter-1))

}elseif($VMWareConfigurationExpander.IsExpanded -and $ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 75 + 40*($Global:HostCounter-1))

}elseif($VMWareConfigurationExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,700

}else{

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

}



})

#Expander VMWare Configuration when is opening...
$VMWareConfigurationExpander.Add_Expanded({
#Raises the Expanded event when the IsExpanded property changes from false to true. Expander is opening..
 
if($VMWareConfigurationExpander.IsExpanded -and $VMExpander.IsExpanded -and $ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 220 + 40*($Global:HostCounter-1) + 40*($Global:VMCounter-1))

}elseif($VMWareConfigurationExpander.IsExpanded -and $VMExpander.IsExpanded -and !$ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 100 + 40*($Global:VMCounter-1))

}elseif($VMWareConfigurationExpander.IsExpanded -and !$VMExpander.IsExpanded -and $ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 20 + 40*($Global:HostCounter-1))

}elseif($VMWareConfigurationExpander.IsExpanded -and !$VMExpander.IsExpanded -and !$ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,700

}

})

#Expander NFS IF Configuration when is closing...
$NFSIPCONFIGURATIONExpander.Add_Collapsed({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is closing.. 

if($FCDATASTORECONFIGURATIONExpander.IsExpanded -and !$DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0 
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,170
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,170

}elseif(!$FCDATASTORECONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0 
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,310

}elseif($FCDATASTORECONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0 
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,170
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,490

}else{

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0 
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

}

})

$NFSIPCONFIGURATIONExpander.Add_Expanded({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is opening.. 

if($FCDATASTORECONFIGURATIONExpander.IsExpanded -and !$DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,290
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,290

}elseif(!$FCDATASTORECONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,430

}elseif($FCDATASTORECONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,290
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,600

}else{

$FCDATASTORECONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120

}

})

$FCDATASTORECONFIGURATIONExpander.Add_Collapsed({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is closing.. 

if($NFSIPCONFIGURATIONExpander.IsExpanded -and !$DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120

}elseif(!$NFSIPCONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,315

}elseif($NFSIPCONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,430

}elseif(!$NFSIPCONFIGURATIONExpander.IsExpanded -and !$DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

}


})

$FCDATASTORECONFIGURATIONExpander.Add_Expanded({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is opening.. 

if($NFSIPCONFIGURATIONExpander.IsExpanded -and !$DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,300
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,300

}elseif(!$NFSIPCONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,170
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,480

}elseif($NFSIPCONFIGURATIONExpander.IsExpanded -and $DATANFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,290
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,600

}else{
$DATANFSIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,180
$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,180
}


})

$DATANFSIPCONFIGURATIONExpander.Add_Collapsed({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is closing.. 


if($NFSIPCONFIGURATIONExpander.IsExpanded -and $FCDATASTORECONFIGURATIONExpander.IsExpanded){ #Checked

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,300

}elseif($NFSIPCONFIGURATIONExpander.IsExpanded -and !$FCDATASTORECONFIGURATIONExpander.IsExpanded){ #Checked 

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,120

}elseif(!$NFSIPCONFIGURATIONExpander.IsExpanded -and $FCDATASTORECONFIGURATIONExpander.IsExpanded){ #Checked

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,180

}elseif(!$NFSIPCONFIGURATIONExpander.IsExpanded -and !$FCDATASTORECONFIGURATIONExpander.IsExpanded){ #Checked

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

}

})

$DATANFSIPCONFIGURATIONExpander.Add_Expanded({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is opening.. 

if($FCDATASTORECONFIGURATIONExpander.IsExpanded -and !$NFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,500

}elseif($FCDATASTORECONFIGURATIONExpander.IsExpanded -and $NFSIPCONFIGURATIONExpander.IsExpanded){

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,605

}elseif(!$FCDATASTORECONFIGURATIONExpander.IsExpanded -and $NFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,430

}elseif(!$FCDATASTORECONFIGURATIONExpander.IsExpanded -and !$NFSIPCONFIGURATIONExpander.IsExpanded){ #Checked

$iSCSIIPCONFIGURATIONExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,320

}

})

#Expander VMWare Configuration when is closing...
$ESXiServersExpander.Add_Collapsed({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is closing.. 

$VMExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,0

if($VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(40*($Global:HostCounter-1))

}elseif(!$VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,700

}


})

#Expander VMWare Configuration when is opening...
$ESXiServersExpander.Add_Expanded({
#Raises the Expanded event when the IsExpanded property changes from false to true. Expander is opening.. 

$VMExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(150 + 40*($Global:HostCounter-1))

if($VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 40*($Global:HostCounter-1) + 40*($Global:VMCounter-1))

}elseif(!$VMExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 40*($Global:HostCounter-1))

}

})

$VMExpander.Add_Collapsed({
#Raises the Collapsed event when the IsExpanded property changes from true to false. Expander is closing.. 
if($ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 40*($Global:HostCounter-1))

}elseif(!$ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,700

}

})

$VMExpander.Add_Expanded({
#Raises the Expanded event when the IsExpanded property changes from false to true. Expander is opening.. 

if($ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 40*($Global:HostCounter-1) + 40*($Global:VMCounter-1))

}elseif(!$ESXiServersExpander.IsExpanded){

$SVMConfigurationExpander.RenderTransform = New-Object System.Windows.Media.TranslateTransform -ArgumentList 0,(700 + 40*($Global:VMCounter-1))

}

})

$NFSRadioButton.Add_Checked({

$FCLIFPORTDATASTORETextBox.IsEnabled = $false
$DATAiSCSILIFIP1TextBox.IsEnabled = $false 
$DATAiSCSILIFGW1TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK1TextBox.IsEnabled = $false
$DATAiSCSILIFPORT1TextBox.IsEnabled = $false

$DATAiSCSILIFIP2TextBox.IsEnabled = $false
$DATAiSCSILIFGW2TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK2TextBox.IsEnabled = $false
$DATAiSCSILIFPORT2TextBox.IsEnabled = $false

$DATAiSCSILIFIP3TextBox.IsEnabled = $false
$DATAiSCSILIFGW3TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK3TextBox.IsEnabled = $false
$DATAiSCSILIFPORT3TextBox.IsEnabled = $false

$DATAiSCSILIFIP4TextBox.IsEnabled = $false
$DATAiSCSILIFGW4TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK4TextBox.IsEnabled = $false
$DATAiSCSILIFPORT4TextBox.IsEnabled = $false

$DATAFCLIF1PORTNODE1TextBox.IsEnabled = $false
$DATAFCLIF2PORTNODE1TextBox.IsEnabled = $false
$DATAFCLIF1PORTNODE2TextBox.IsEnabled = $false
$DATAFCLIF2PORTNODE2TextBox.IsEnabled = $false

$DATANFSLIFIP1TextBox.IsEnabled = $true
$DATANFSLIFGWTextBox.IsEnabled = $true
$DATANFSLIFNETMASKTextBox.IsEnabled = $true
$DATANFSLIFPORT1TextBox.IsEnabled = $true

$DATANFSLIFIP2TextBox.IsEnabled = $true
$DATANFSLIFPORT2TextBox.IsEnabled = $true

$DATANFSLIFIP3TextBox.IsEnabled = $true
$DATANFSLIFPORT3TextBox.IsEnabled = $true

$DATANFSLIFIP4TextBox.IsEnabled = $true
$DATANFSLIFPORT4TextBox.IsEnabled = $true

$FileSizeTextBox.IsEnabled = $true
$LunIDTextBox.IsEnabled = $false


})

$iSCSIRadioButton.Add_Checked({

$FCLIFPORTDATASTORETextBox.IsEnabled = $false
$DATAiSCSILIFIP1TextBox.IsEnabled = $true 
$DATAiSCSILIFGW1TextBox.IsEnabled = $true
$DATAiSCSILIFNETMASK1TextBox.IsEnabled = $true
$DATAiSCSILIFPORT1TextBox.IsEnabled = $true

$DATAiSCSILIFIP2TextBox.IsEnabled = $true
$DATAiSCSILIFGW2TextBox.IsEnabled = $true
$DATAiSCSILIFNETMASK2TextBox.IsEnabled = $true
$DATAiSCSILIFPORT2TextBox.IsEnabled = $true

$DATAiSCSILIFIP3TextBox.IsEnabled = $true
$DATAiSCSILIFGW3TextBox.IsEnabled = $true
$DATAiSCSILIFNETMASK3TextBox.IsEnabled = $true
$DATAiSCSILIFPORT3TextBox.IsEnabled = $true

$DATAiSCSILIFIP4TextBox.IsEnabled = $true
$DATAiSCSILIFGW4TextBox.IsEnabled = $true
$DATAiSCSILIFNETMASK4TextBox.IsEnabled = $true
$DATAiSCSILIFPORT4TextBox.IsEnabled = $true

$DATAFCLIF1PORTNODE1TextBox.IsEnabled = $false
$DATAFCLIF2PORTNODE1TextBox.IsEnabled = $false
$DATAFCLIF1PORTNODE2TextBox.IsEnabled = $false
$DATAFCLIF2PORTNODE2TextBox.IsEnabled = $false

$DATANFSLIFIP1TextBox.IsEnabled = $false
$DATANFSLIFGWTextBox.IsEnabled = $false
$DATANFSLIFNETMASKTextBox.IsEnabled = $false
$DATANFSLIFPORT1TextBox.IsEnabled = $false

$DATANFSLIFIP2TextBox.IsEnabled = $false
$DATANFSLIFPORT2TextBox.IsEnabled = $false

$DATANFSLIFIP3TextBox.IsEnabled = $false
$DATANFSLIFPORT3TextBox.IsEnabled = $false

$DATANFSLIFIP4TextBox.IsEnabled = $false
$DATANFSLIFPORT4TextBox.IsEnabled = $false

$FileSizeTextBox.IsEnabled = $false
$LunIDTextBox.IsEnabled = $true

})

$FCRadioButton.Add_Checked({

$FCLIFPORTDATASTORETextBox.IsEnabled = $true
$DATAiSCSILIFIP1TextBox.IsEnabled = $false 
$DATAiSCSILIFGW1TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK1TextBox.IsEnabled = $false
$DATAiSCSILIFPORT1TextBox.IsEnabled = $false

$DATAiSCSILIFIP2TextBox.IsEnabled = $false
$DATAiSCSILIFGW2TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK2TextBox.IsEnabled = $false
$DATAiSCSILIFPORT2TextBox.IsEnabled = $false

$DATAiSCSILIFIP3TextBox.IsEnabled = $false
$DATAiSCSILIFGW3TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK3TextBox.IsEnabled = $false
$DATAiSCSILIFPORT3TextBox.IsEnabled = $false

$DATAiSCSILIFIP4TextBox.IsEnabled = $false
$DATAiSCSILIFGW4TextBox.IsEnabled = $false
$DATAiSCSILIFNETMASK4TextBox.IsEnabled = $false
$DATAiSCSILIFPORT4TextBox.IsEnabled = $false

$DATAFCLIF1PORTNODE1TextBox.IsEnabled = $true
$DATAFCLIF2PORTNODE1TextBox.IsEnabled = $true
$DATAFCLIF1PORTNODE2TextBox.IsEnabled = $true
$DATAFCLIF2PORTNODE2TextBox.IsEnabled = $true

$DATANFSLIFIP1TextBox.IsEnabled = $false
$DATANFSLIFGWTextBox.IsEnabled = $false
$DATANFSLIFNETMASKTextBox.IsEnabled = $false
$DATANFSLIFPORT1TextBox.IsEnabled = $false

$DATANFSLIFIP2TextBox.IsEnabled = $false
$DATANFSLIFPORT2TextBox.IsEnabled = $false

$DATANFSLIFIP3TextBox.IsEnabled = $false
$DATANFSLIFPORT3TextBox.IsEnabled = $false

$DATANFSLIFIP4TextBox.IsEnabled = $false
$DATANFSLIFPORT4TextBox.IsEnabled = $false

$FileSizeTextBox.IsEnabled = $false
$LunIDTextBox.IsEnabled = $true

})

$DSwitchRadioButton.Add_Checked({

$NetworkNameTextBox.IsEnabled = $true
$PortGroupNameTextBox.IsEnabled = $false   

})

$VSWITCHRadioButton.Add_Checked({

$NetworkNameTextBox.IsEnabled = $false
$PortGroupNameTextBox.IsEnabled = $true

})

$Window.showdialog()

}

##############################################################
##############################################################
##############################################################
##############################################################
##############################################################
##############################################################
##############################################################
##############################################################
##############################################################
