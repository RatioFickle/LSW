![LSW Banner](lsw-banner.png)
# LSW Optimizer: Extreme RAM reducer for Windows Server 2022 VMs (WinApps/RDP)
## English 🇬🇧 
  **LSW Optimizer** is a pioneering configuration matrix designed to aggressively debloat Windows Server, transforming it into an ultra-lightweight backend tailored specifically for Linux environments to create a true "Linux Subsystem for Windows". By mercilessly stripping away telemetry, background services, Windows Defender, and unnecessary UI bloat, the script reduces the operating system's idle footprint to an astonishing 200-300 MB of RAM. Ultimately, it provides a seamless and highly efficient RDP/WinApps bridge, ensuring that your wife can smoothly run the latest Microsoft Word directly on her Linux desktop, or your boss can flawlessly present a PowerPoint, all without ever realizing a virtual machine is running under the hood.

### 💻 Getting Started
1. **Get the OS:** Download the official [Windows Server 2022 Evaluation ISO](https://info.microsoft.com/ww-landing-windows-server-2022.html) and officially become a Microsoft "homelab developer" 😉.
2. **Run the Optimizer:** Simply download the `LSW_Optimizer.cmd` file from this repository, place it on your VM's desktop, and double-click it. 

*Alternatively, open PowerShell as Administrator and paste this pro one-liner:*
```powershell
irm https://raw.githubusercontent.com/RatioFickle/LSW/main/LSW_Optimizer.cmd | iex
```
## 🚀 LSW in action (Seamless Mode)
Here’s proof that extreme optimization makes sense. Native Microsoft Word 2024 (on Windows) running directly on the Ubuntu (Linux) desktop using WinApps, with minimal resource usage:

![LSW Word na Linuksie](lsw-word-on-linux.png)
