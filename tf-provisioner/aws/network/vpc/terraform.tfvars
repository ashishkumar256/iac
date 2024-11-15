environment = {
  dc01 = {
    main = {
      region = "ap-south-1"
      cidr   = "10.91.0.0/16"
      nat_gw = {
        HA                = true
        Preffered_data_AZ = "ap-south-1a"
      },
      endpoint = {
        gateway   = ["s3", "dynamodb"]
        interface = ["ecr.api", "ecr.dkr"]
        # interface_endpoint = ["ecr.api", "ecr-dkr"] #["logs", "ecr-api", "ecr-dkr", "ec2", "kms", "elasticloadbalancing", "autoscaling", "sts", "lambda", "eks", "ecs", "secretsmanager", "sns", "sqs" ]
      },
      peering = {      
        acceptor = {
          1 = {
            src_vpc_region_alias = "dc02"
            src_vpc_logical_name = "main"            
          }
          2 = {
            src_vpc_region_alias = "dc02"
            src_vpc_logical_name = "dummy"            
          }          
        }            
      }
      subnets = {
        "ap-south-1a" = {
          protected = ["10.91.0.0/18"],
          private   = ["10.91.200.0/21"],
          public    = ["10.91.232.0/21"]
        },
        "ap-south-1b" = {
          protected = ["10.91.64.0/18"],
          private   = ["10.91.208.0/21"],
          public    = ["10.91.240.0/21"]
        },
        "ap-south-1c" = {
          protected = ["10.91.128.0/18"],
          private   = ["10.91.216.0/21"],
          public    = ["10.91.248.0/21"]
        }
      }
      additional_cidr = {
        secondary = {
          cidr = "10.92.0.0/16"
          subnets = {
            "ap-south-1a" = {
              protected = ["10.92.0.0/18"],
              private   = ["10.92.200.0/21"],
              public    = ["10.92.232.0/21"]
            },
            "ap-south-1b" = {
              protected = ["10.92.64.0/18"],
              private   = ["10.92.208.0/21"],
              public    = ["10.92.240.0/21"]
            },
          },
          NAT_GW = {
            self              = true
            HA                = false
            Preffered_data_AZ = "ap-south-1a"
          }
        },
        tertiary = {
          cidr = "10.93.0.0/16"
          subnets = {
            "ap-south-1a" = {
              # protected = ["10.93.0.0/18"],
              protected = ["10.93.0.0/19", "10.93.32.0/19"]
              private   = ["10.93.200.0/21"],
              public    = ["10.93.232.0/21"]
            },
            "ap-south-1b" = {
              protected = ["10.93.64.0/18"],
              private   = ["10.93.208.0/21"],
              public    = ["10.93.240.0/21"]
            },
          }
          NAT_GW = {
            self              = true
            HA                = true
            Preffered_data_AZ = "ap-south-1a"
          }
        }
      }
    }


    poc = {
      region = "ap-south-1"
      cidr   = "10.94.0.0/16"
      nat_gw = {
        HA                = true
        Preffered_data_AZ = "ap-south-1a"
      },
      endpoint = {
        gateway   = ["s3", "dynamodb"]
        interface = ["ecr.api", "ecr.dkr"]
      }    
      peering = {      
        acceptor = {
          1 = {
            src_vpc_region_alias = "dc02"
            src_vpc_logical_name = "main"            
          }      
        }            
      }      
      subnets = {
        "ap-south-1a" = {
          protected = ["10.94.0.0/18"],
          private   = ["10.94.200.0/21"],
          public    = ["10.94.232.0/21"]
        },
        "ap-south-1b" = {
          protected = ["10.94.64.0/18"],
          private   = ["10.94.208.0/21"],
          public    = ["10.94.240.0/21"]
        },
        "ap-south-1c" = {
          protected = ["10.94.128.0/18"],
          private   = ["10.94.216.0/21"],
          public    = ["10.94.248.0/21"]
        }
      }
    }
  }

  dc02 = {
    main = {
      region = "ap-south-1"
      cidr   = "10.95.0.0/16"
      nat_gw = {
        HA                = true
        Preffered_data_AZ = "ap-south-1a"
      },
      endpoint = {
        gateway   = ["s3", "dynamodb"]
        interface = ["ecr.api", "ecr.dkr"]
      }    
      peering = {
        creator = {
          1 = {
            dst_vpc_alias = "dc01"
            dst_vpc_id_alias = "main"
          }   
          2 = {
            dst_vpc_alias = "dc01"
            dst_vpc_id_alias = "poc"
          }              
        }    
      }
      subnets = {
        "ap-south-1a" = {
          protected = ["10.95.0.0/18"],
          private   = ["10.95.200.0/21"],
          public    = ["10.95.232.0/21"]
        },
        "ap-south-1b" = {
          protected = ["10.95.64.0/18"],
          private   = ["10.95.208.0/21"],
          public    = ["10.95.240.0/21"]
        },
        "ap-south-1c" = {
          protected = ["10.95.128.0/18"],
          private   = ["10.95.216.0/21"],
          public    = ["10.95.248.0/21"]
        }
      }
    }

    dummy = {
      region = "ap-south-1"
      cidr   = "10.96.0.0/16"
      nat_gw = {
        HA                = false
        Preffered_data_AZ = "ap-south-1a"
      },
      endpoint = {
        gateway   = ["s3", "dynamodb"]
        interface = ["ecr.api", "ecr.dkr"]
      }    
      peering = {
        creator = { 
          1 = {
            dst_vpc_alias = "dc01"
            dst_vpc_id_alias = "main"
          }              
        }    
      }
      subnets = {
        "ap-south-1a" = {
          protected = ["10.96.0.0/18"],
          private   = ["10.96.200.0/21"],
          public    = ["10.96.232.0/21"]
        },
        "ap-south-1b" = {
          protected = ["10.96.64.0/18"],
          private   = ["10.96.208.0/21"],
          public    = ["10.96.240.0/21"]
        },
        "ap-south-1c" = {
          protected = ["10.96.128.0/18"],
          private   = ["10.96.216.0/21"],
          public    = ["10.96.248.0/21"]
        }
      }
    }    
  }  

}


