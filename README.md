# POC-Scripts
vdbench POSH POC Scripts
Please find below the prerequisite to run the script: 

•	Windows JumpHost.
•	Powershell 5.0 or above.
•	Posh-SSH – If the Windows VM has internet access, the Script can install this as part of the prechecks.   
•	PowerCLI 6.5 – If the Windows VM has internet access, the Script can install this as part of the prechecks.   
•	Netapp Powershell tool kit 4.5 

The OVA and the Configuration files can be found in the below link. Please create a copy of the file named “ConfigFile” and modify the copy according to your environment. I have added some examples of the config files for FCP/NFS and iSCSI for guidance. If you need further assistance let me know. 
https://netapp-my.sharepoint.com/personal/gjorge_netapp_com/_layouts/15/guestaccess.aspx?guestaccesstoken=VvVTfrEcipez8LvwJXwR9CIb4S%2F5%2Bl%2BPi1pqEuxc5Ls%3D&docid=2_1308296e5031f4729896247608872fdae&rev=1&e=cOiZgy

So far the script is capable of deploying vdbench for FCP, iSCSI and NFS. After deployment the end user only needs to issue “vdbench -f <workload definitions>” to start the performance test. 
The script includes the following features:
  
•	Creation of the SVM (e.g. vdbench_FCP/NFS/iSCSI) that is going to host all the volumes for the performance test.
•	Creation of the NFS data lifs – it depends on the number of physical ports available for the test. 
•	Creation of a NFS/iSCSI/FCP Datastore in VMware that is going to host all the files of the Centos vdbench workers. 
•	Automatic import of the OVA to VMware that contains all the requirements to run vdbench.
•	Automatic Cloning of the VMs – it is possible to deploy multiple VMs per host. 
•	Creation of the NFS/iSCSI/FCP volumes which are spread between two data aggregates – 4 volumes per VMs. 
•	Automatic DNS configuration on the VMs as the host file is changed in each vdbench Worker.
•	Automatic Creation and mounting of a NFS export where all the configuration files of vdbench are kept. 
•	Import of the vdbench binaries – (you can download the binaries from the Oracle website, you need to create an Account with Oracle)  http://www.oracle.com/technetwork/server-storage/vdbench-downloads-1901681.html
•	Automatic configuration of the vdbench files (e.g for FCP  “aff-host-fcp” “aff-luns-fcp”)
•	Automatic mounting of the NFS volumes to the vdbench Workers. “mount -t nfs” and also the script is capable of changing the /etc/fstab file to make the NFS mountings permanent – This is only for NFS.
•	Decommission of the whole environment (Deletion of the VMs, Volumes and SVM).
