{
    "LIFSNFS":  {
                    "lif3":  {
                                 "Netmask":  "Enter Netmask for NFS traffic...",
                                 "Port":  "Enter 10GbE port node 2...",
                                 "IP":  "Enter IP Address 3...",
                                 "Name":  "vdbench_GUI_nfs_node02-lif-1",
                                 "Gateway":  "Enter Gateway for NFS traffic..."
                             },
                    "lif2":  {
                                 "Netmask":  "Enter Netmask for NFS traffic...",
                                 "Port":  "Enter 10GbE port node 1...",
                                 "IP":  "Enter IP Address 2 ...",
                                 "Name":  "vdbench_GUI_nfs_node01-lif-2",
                                 "Gateway":  "Enter Gateway for NFS traffic..."
                             },
                    "lif1":  {
                                 "Netmask":  "Enter Netmask for NFS traffic...",
                                 "Port":  "Enter 10GbE port node 1...",
                                 "IP":  "Enter IP Address 1 ...",
                                 "Name":  "vdbench_GUI_nfs_node01-lif-1",
                                 "Gateway":  "Enter Gateway for NFS traffic..."
                             },
                    "lif4":  {
                                 "Netmask":  "Enter Netmask for NFS traffic...",
                                 "Port":  "Enter 10GbE port node 2...",
                                 "IP":  "Enter IP Address 4...",
                                 "Name":  "vdbench_GUI_nfs_node02-lif-2",
                                 "Gateway":  "Enter Gateway for NFS traffic..."
                             }
                },
    "Other":  {
                  "iSCSI":  false,
                  "PortGroupName":  "Enter the Network Name of the DVSwitch...",
                  "ESXiCluster":  "Cluster 1",
                  "FileSize":  "Enter file size..",
                  "NetworkName":  "DPortGroup VM Network",
                  "Pathvdbench":  "C:\\Users\\Administrator\\Desktop\\poc-toolkit-Netappv1\\vdbench50406.zip",
                  "LunID":  "200",
                  "ClusterIP":  "192.168.0.100",
                  "Jumbo":  false,
                  "FC":  true,
                  "VCenterIP":  "192.168.0.150",
                  "PathOVA":  "C:\\Users\\Administrator\\Desktop\\poc-toolkit-Netappv1\\vdbench-template.ova",
                  "DSwitch":  true,
                  "NumberVMperhost":  "1",
                  "NFS":  false,
                  "VolumeSize":  "126"
              },
    "LIFSiSCSI":  {
                      "lif6":  {
                                   "Netmask":  "Enter Netmask...",
                                   "Port":  "Enter 10GbE port...",
                                   "IP":  "Enter IP Address...",
                                   "Name":  "vdbench_GUI_iscsi_node01-lif-2",
                                   "Gateway":  "Enter Gateway..."
                               },
                      "lif5":  {
                                   "Netmask":  "Enter Netmask...",
                                   "Port":  "Enter 10GbE port...",
                                   "IP":  "Enter IP Address...",
                                   "Name":  "vdbench_GUI_iscsi_node01-lif-1",
                                   "Gateway":  "Enter Gateway..."
                               },
                      "lif8":  {
                                   "Netmask":  "Enter Netmask...",
                                   "Port":  "Enter 10GbE port...",
                                   "IP":  "Enter IP Address...",
                                   "Name":  "vdbench_GUI_iscsi_node02-lif-2",
                                   "Gateway":  "Enter Gateway..."
                               },
                      "lif7":  {
                                   "Netmask":  "Enter Netmask...",
                                   "Port":  "Enter 10GbE port...",
                                   "IP":  "Enter IP Address...",
                                   "Name":  "vdbench_GUI_iscsi_node02-lif-1",
                                   "Gateway":  "Enter Gateway..."
                               }
                  },
    "Hosts":  {
                  "Host02":  {
                                 "Name":  "x3550-m3-31.cpoc.local"
                             },
                  "Host00":  {
                                 "Name":  "x3550-m3-50.cpoc.local"
                             },
                  "Host01":  {
                                 "Name":  "x3550-m3-52.cpoc.local"
                             },
                  "Host04":  {
                                 "Name":  "x3550-m3-51.cpoc.local"
                             },
                  "Host03":  {
                                 "Name":  "x3550-m3-53.cpoc.local"
                             }
              },
    "VMsLIF":  {
                   "lif1":  {
                                "Name":  "vdbench_GUI_FC",
                                "Port":  "0e"
                            },
                   "lif0":  {
                                "Netmask":  "255.255.255.0",
                                "Port":  "e1a",
                                "IP":  "192.168.0.59",
                                "Name":  "vdbench_GUI",
                                "Gateway":  "192.168.0.1"
                            }
               },
    "VMs":  {
                "VM01":  {
                             "IP":  "192.168.0.61",
                             "Name":  "vdbench_GUI_Test01"
                         },
                "VM02":  {
                             "IP":  "192.168.0.62",
                             "Name":  "vdbench_GUI_Test02"
                         },
                "VM03":  {
                             "IP":  "192.168.0.63",
                             "Name":  "vdbench_GUI_Test03"
                         },
                "VM04":  {
                             "IP":  "192.168.0.64",
                             "Name":  "vdbench_GUI_Test04"
                         },
                "VM00":  {
                             "Netmask":  "255.255.255.0",
                             "IP":  "192.168.0.60",
                             "Name":  "vdbench_GUI_Test00",
                             "Gateway":  "192.168.0.1"
                         }
            },
    "LIFSFC":  {
                   "lif11":  {
                                 "Name":  "vdbench_GUI_FC_node02-lif-1",
                                 "Port":  "0e"
                             },
                   "lif9":  {
                                "Name":  "vdbench_GUI_FC_node01-lif-1",
                                "Port":  "0e"
                            },
                   "lif10":  {
                                 "Name":  "vdbench_GUI_FC_node01-lif-2",
                                 "Port":  "0f"
                             },
                   "lif12":  {
                                 "Name":  "vdbench_GUI_FC_node02-lif-2",
                                 "Port":  "0f"
                             }
               },
    "SVM":  {
                "Name":  "vdbench_GUI"
            }
}
