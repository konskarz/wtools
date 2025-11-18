# Personal Computing Method

> Organize and manage digital work and tools in a way that separates concerns, controls replication, and supports reproducibility, to maintain control over data and workflows, reduce risk of data loss, and ensure consistent environments across devices.

```mermaid
graph LR
  os[OS]
  subgraph data[User Data]
    subgraph depot[Nonreplicable Data]
      apps[App Components]
      sys[OS Components]
    end
    subgraph docs[Replicable Data]
      subgraph env[Environment Management]
        wtools[App Management]
        wpt[OS Management]
      end
      subgraph prv[Private Data]
        bak[Service Backups]
        share[Synced Data]
      end
      wf[Workflow Data]
      pub[Published Data]
      lib[External Data]
    end
  end
  cloud([Cloud])
  removable[[Removable Media]]

  docs -.->|mirror| removable
  pub -.->|upload| cloud
  cloud -.->|download| bak & lib
  env & wf & share <-.->|sync| cloud
  wtools --> apps
  wpt --> sys & os

  classDef finalized fill:#c7f7d9,stroke:#8fd8a4;
  classDef current fill:#c7e0fa,stroke:#89b4e9;
  classDef external fill:#f5f0d9,stroke:#d8d0a4;
  classDef private fill:#f1dcf9,stroke:#d2a9eb;
  classDef appsrv fill:#cfe2f3,stroke:#9fc5e8
  classDef device fill:#ead1dc,stroke:#d5a6bd

  class pub finalized
  class wtools,wpt,wf current
  class bak,share private
  class lib external
  class cloud appsrv
  class removable device

  click wtools "https://github.com/konskarz/wtools"
  click wpt "https://github.com/konskarz/wpt"
```

- **Removable Media**: External storage (e.g., SD-card, phone storage) for local replication to ensure availability offline across devices
- **Cloud**: Cloud Libraries, Services, Storage, Version Control Systems for data consumption, publication and synchronization across devices, use online sync only for actively edited data
- **User Data**: separate OS and user data to reduce risk of data loss
- **Replicable Data**: separate data that should be replicated locally to reduce risk of loss and ensure availability offline across devices
- **Nonreplicable Data**: separate data that doesn’t need replication to optimize storage usage
- **App Components**: portable apps, packages
- **OS Components**: OS images, drivers, updates
- **App Management**: separate app management, used for portability, automation, and workspace integration to enable reproducible workflows across devices, and synchronize it via services to keep it editable across devices
- **OS Management**: separate OS management, used for setup, recovery, and post-install tasks automation, to maintain stable environments, and synchronize it via services to keep configurations consistent across devices
- **Workflow Data**: separate workflow data, synchronized via services to keep it editable across devices
- **Published Data**: separate data intended for publication
- **Private Data**: separate personal data from workflow data to maintain control and privacy
- **Service Backups**: backup personal data from external services to reduce risk of loss
- **Synced Data**: separate personal data synchronized via services to keep it editable across devices
- **External Data**: separate data for consumption, created by others, to avoid mixing with personal workflows and ensure availability offline across devices
