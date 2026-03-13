![LSW Banner](lsw-banner.png)
# LSW Optimizer: Extreme RAM reducer for Windows Server 2022 VMs (WinApps/RDP)
## English 🇬🇧 
  **LSW Optimizer** is a pioneering configuration matrix designed to aggressively debloat Windows Server, transforming it into an ultra-lightweight backend tailored specifically for Linux environments to create a true "Linux Subsystem for Windows". By mercilessly stripping away telemetry, background services, Windows Defender, and unnecessary UI bloat, the script reduces the operating system's idle footprint to an astonishing 200-300 MB of RAM. Ultimately, it provides a seamless and highly efficient RDP/WinApps bridge, ensuring that your wife can smoothly run the latest Microsoft Word directly on her Linux desktop, or your boss can flawlessly present a PowerPoint, all without ever realizing a virtual machine is running under the hood.

### 🚀 Getting Started
1. **Get the OS:** Download the official [Windows Server 2022 Evaluation ISO](https://info.microsoft.com/ww-landing-windows-server-2022.html) and officially become a Microsoft "homelab developer" 😉.
2. **Run the Optimizer:** Simply download the `LSW_Optimizer.cmd` file from this repository, place it on your VM's desktop, and double-click it. 

*Alternatively, open PowerShell as Administrator and paste this pro one-liner:*
```powershell
irm https://raw.githubusercontent.com/RatioFickle/LSW/main/LSW_Optimizer.cmd | iex
```

## 中文 🇨🇳

  **LSW Optimizer** 是一款开创性的配置脚本，旨在对 Windows Server 进行极限精简，将其转化为专门为 Linux 环境量身定制的超轻量级后端，从而打造出真正的“Windows 的 Linux 子系统”(Linux Subsystem for Windows)。通过无情地剥离遥测数据、后台服务、Windows Defender 以及不必要的 UI 臃肿程序，该脚本将操作系统的闲置内存占用降至惊人的 200-300 MB。最终，它提供了一个无缝且高效的 RDP/WinApps 桥梁，确保你的妻子可以在她的 Linux 桌面上流畅运行最新的 Microsoft Word，或者你的老板可以完美地展示 PowerPoint，而他们甚至都不会察觉到后台其实正在运行一个虚拟机。

### 🚀 如何开始 (Getting Started)

1. **获取系统:** 下载官方的 Windows Server 2022 评估版 ISO，正式成为微软的“家庭实验室开发者” 😉。

2. **运行优化器:** 只需下载本仓库中的 LSW_Optimizer.cmd 文件，将其放在虚拟机的桌面上并双击运行即可。

*或者，以管理员身份打开 PowerShell 并直接粘贴此一键命令：*
```PowerShell
irm https://raw.githubusercontent.com/RatioFickle/LSW/main/LSW_Optimizer.cmd | iex
```
