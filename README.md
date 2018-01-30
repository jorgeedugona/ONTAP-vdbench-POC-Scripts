# POC-Scripts  
NetApp vdbench POSH POC Scripts  

### Main Menu Image
<p align="center">
  <img src="https://github.com/jorgeedugona/POC-Scripts/blob/readme-edits/Images/MainMenu.JPG?raw=true" alt="Main Menu"/> <img src="https://github.com/jorgeedugona/POC-Scripts/blob/readme-edits/Images/ScriptRunning.JPG?raw=true" alt="Script Running"/>
</p>

Please find below the prerequisites to run the script:  

•	Windows JumpHost.  
•	Powershell 5.0 or above.
•	Posh-SSH – If the jumpHost has internet access, the Script can install this as part of the prechecks.     
•	PowerCLI 6.5 – If the jumpHost has internet access, the Script can install this as part of the prechecks.    
•	NetApp Powershell toolkit 4.5.
• zip file of the vdbench binaries (the binaries can be downloaded from the Oracle website, an account with Oracle is needed).   
http://www.oracle.com/technetwork/server-storage/vdbench-downloads-1901681.html  


The OVA file can be found in the below link. I have added some examples of the config files for FCP,NFS and iSCSI for guidance. If you need further assistance let me know.  
https://netapp-my.sharepoint.com/:u:/p/gjorge/EXMn4dlEzaxBrsUsKJvJE20BfzsSwDAzFnxmznROouu6Vg?e=N6lLj4  

The script is capable of deploying vdbench for FCP, iSCSI and NFS for Ontap 9.0 platforms. After deployment the end user only needs to issue “vdbench -f <workload definitions>” to start the performance test (e.g vdbench -f 00-aff-basic-test-nfs).  
The script includes the following features:  

• Installation of POSH-SSH and PowerCLI 6.5 if needed. (NetApp PowerShell toolkit 4.5 needs to be installed manually).  
• Creation of a new configuration file.  
• Import of an existing configuration file.  
•	Creation of the SVM (e.g. vdbench_FCP/NFS/iSCSI) that is going to host all the volumes and VM workers for the performance test.  
•	Creation of 4 NFS/iSCSI/FC data lifs (e.g 4 FC data lifs will be created for FC test).  
•	Creation of a NFS/iSCSI/FCP Datastore in VMware that is going to host all the files of the Centos VM workers.  
•	Import of the OVA (vdbench-template.ova) to the NFS/iSCSI/FC datastore that contains all the requirements to run vdbench.  
•	Cloning of the VMs – It is possible to deploy multiple VMs per host.  
•	Creation of the NFS/iSCSI/FCP volumes which are spread between two data aggregates–4 volumes per VMs (e.g 16 Volumes will be created for 4 VMs).  
•	Mounting of the NFS volumes to the vdbench Workers. “mount -t nfs” and also the script is capable of changing the /etc/fstab file to make the NFS mountings permanent – This is only for NFS.  
•	DNS configuration on the VMs workers, /etc/hosts file is changed in each vdbench worker. DHCP server is not needed.  
•	Creation and mounting of a NFS export where all the configuration files of vdbench are kept. This is always created regarless what protocol is being tested.  
•	Import of the vdbench binaries – (the binaries can be downloaded from the Oracle website, an account with Oracle is needed).  
http://www.oracle.com/technetwork/server-storage/vdbench-downloads-1901681.html  
•	Configuration of the vdbench files (e.g for FCP  “aff-host-fcp” “aff-luns-fcp”).  
•	Decommission of the whole environment (Deletion of the VMs, Volumes and SVM).  
