{
    "LIFSNFS":  {
                    "lif1":  {
                                 "Netmask":  "255.255.255.0",
                                 "Port":  "a0a-20",
                                 "IP":  "192.168.0.101",
                                 "Name":  "vdbench_GUI_nfs_node01-lif-1",
                                 "Gateway":  "192.168.0.1"
                             },
                    "lif3":  {
                                 "Netmask":  "255.255.255.0",
                                 "Port":  "a0a-20",
                                 "IP":  "192.168.0.103",
                                 "Name":  "vdbench_GUI_nfs_node02-lif-1",
                                 "Gateway":  "192.168.0.1"
                             },
                    "lif2":  {
                                 "Netmask":  "255.255.255.0",
                                 "Port":  "a0a-20",
                                 "IP":  "192.168.0.102",
                                 "Name":  "vdbench_GUI_nfs_node01-lif-2",
                                 "Gateway":  "192.168.0.1"
                             },
                    "lif4":  {
                                 "Netmask":  "255.255.255.0",
                                 "Port":  "a0a-20",
                                 "IP":  "192.168.0.104",
                                 "Name":  "vdbench_GUI_nfs_node02-lif-2",
                                 "Gateway":  "192.168.0.1"
                             }
                },
    "Other":  {
                  "iSCSI":  true,
                  "PortGroupName":  "",
                  "NumberofVolumesPerVM":  "4",
                  "FileSize":  "",
                  "NetworkName":  "Public",
                  "Pathvdbench":  "C:\\Users\\Administrator\\Desktop\\vdbench50406.zip",
                  "LunID":  "200",
                  "ClusterIP":  "192.168.0.59",
                  "Jumbo":  true,
                  "FC":  false,
                  "VCenterIP":  "192.168.0.20",
                  "PathOVA":  "C:\\Users\\Administrator\\Desktop\\poc-toolkit-NetAppv1.0\\OVA\\vdbench-template.ova",
                  "DSwitch":  true,
                  "NumberVMperhost":  "1",
                  "NFS":  false,
                  "VolumeSize":  "126"
              },
    "LIFSiSCSI":  {
                      "lif7":  {
                                   "Netmask":  "255.255.255.0",
                                   "Port":  "a0a-20",
                                   "IP":  "192.168.0.107",
                                   "Name":  "vdbench_GUI_iscsi_node02-lif-1",
                                   "Gateway":  "192.168.0.1"
                               },
                      "lif5":  {
                                   "Netmask":  "255.255.255.0",
                                   "Port":  "a0a-20",
                                   "IP":  "192.168.0.105",
                                   "Name":  "vdbench_GUI_iscsi_node01-lif-1",
                                   "Gateway":  "192.168.0.1"
                               },
                      "lif8":  {
                                   "Netmask":  "255.255.255.0",
                                   "Port":  "a0a-20",
                                   "IP":  "192.168.0.108",
                                   "Name":  "vdbench_GUI_iscsi_node02-lif-2",
                                   "Gateway":  "192.168.0.1"
                               },
                      "lif6":  {
                                   "Netmask":  "255.255.255.0",
                                   "Port":  "a0a-20",
                                   "IP":  "192.168.0.106",
                                   "Name":  "vdbench_GUI_iscsi_node01-lif-2",
                                   "Gateway":  "192.168.0.1"
                               }
                  },
    "Hosts":  {
                  "Host03":  {
                                 "Name":  "192.168.0.92"
                             },
                  "Host00":  {
                                 "Name":  "192.168.0.65"
                             },
                  "Host01":  {
                                 "Name":  "192.168.0.90"
                             },
                  "Host02":  {
                                 "Name":  "192.168.0.91"
                             },
                  "Host04":  {
                                 "Name":  "192.168.0.93"
                             }
              },
    "VMsLIF":  {
                   "lif1":  {
                                "Name":  "vdbench_GUI_FC",
                                "Port":  "Enter FC port..."
                            },
                   "lif0":  {
                                "Netmask":  "255.255.255.0",
                                "Port":  "a0a-20",
                                "IP":  "192.168.0.100",
                                "Name":  "vdbench_GUI",
                                "Gateway":  "192.168.0.1"
                            }
               },
    "VMs":  {
                "VM04":  {
                             "IP":  "192.168.0.48",
                             "Name":  "vdbench_GUI_Test04"
                         },
                "VM03":  {
                             "IP":  "192.168.0.47",
                             "Name":  "vdbench_GUI_Test03"
                         },
                "VM01":  {
                             "IP":  "192.168.0.45",
                             "Name":  "vdbench_GUI_Test01"
                         },
                "VM02":  {
                             "IP":  "192.168.0.46",
                             "Name":  "vdbench_GUI_Test02"
                         },
                "VM00":  {
                             "Netmask":  "255.255.255.0",
                             "IP":  "192.168.0.44",
                             "Name":  "vdbench_GUI_Test00",
                             "Gateway":  "192.168.0.1"
                         }
            },
    "LIFSFC":  {
                   "lif9":  {
                                "Name":  "vdbench_GUI_FC_node01-lif-1",
                                "Port":  "Enter FC port..."
                            },
                   "lif12":  {
                                 "Name":  "vdbench_GUI_FC_node02-lif-2",
                                 "Port":  "Enter FC port..."
                             },
                   "lif11":  {
                                 "Name":  "vdbench_GUI_FC_node02-lif-1",
                                 "Port":  "Enter FC port..."
                             },
                   "lif10":  {
                                 "Name":  "vdbench_GUI_FC_node01-lif-2",
                                 "Port":  "Enter FC port..."
                             }
               },
    "SVM":  {
                "Name":  "vdbench_GUI"
            }
}
