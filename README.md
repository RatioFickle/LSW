![LSW Banner](lsw-banner.png)
# LSW Optimizer: Extreme RAM reducer for Windows Server 2022 VMs (WinApps/RDP)

  **LSW Optimizer** is a pioneering configuration matrix designed to aggressively debloat Windows Server, transforming it into an ultra-lightweight backend tailored specifically for Linux environments to create a true "Linux Subsystem for Windows". By mercilessly stripping away telemetry, background services, Windows Defender, and unnecessary UI bloat, the script reduces the operating system's idle footprint to an astonishing 200-300 MB of RAM. Ultimately, it provides a seamless and highly efficient RDP/WinApps bridge, ensuring that your wife can smoothly run the latest Microsoft Word directly on her Linux desktop, or your boss can flawlessly present a PowerPoint, all without ever realizing a virtual machine is running under the hood.

### 💻 Getting Started
1. **Get the OS:** Download the official [Windows Server 2022 Evaluation ISO](https://info.microsoft.com/ww-landing-windows-server-2022.html) and officially become a Microsoft "homelab developer" 😉.
2. **Run the Optimizer:** Simply download the `LSW_Optimizer.cmd` file from this repository, place it on your VM's desktop, and double-click it. 

*Alternatively, open PowerShell as Administrator and paste this pro one-liner:*
```powershell
irm https://raw.githubusercontent.com/RatioFickle/LSW/main/LSW_Optimizer.cmd -OutFile LSW_Optimizer.cmd; .\LSW_Optimizer.cmd
```
## 🚀 LSW in action (Seamless Mode)
Here’s proof that extreme optimization makes sense. Native Microsoft Word 2024 (on Windows) running directly on the Ubuntu (Linux) desktop using WinApps, with minimal resource usage:

![LSW Word na Linuksie](lsw-word-on-linux.png)

### 📝 Office Installation
1. Download the official **Office Deployment Tool (ODT)** directly from the Microsoft Download Center:
   👉 [**Microsoft Download Center - Office Deployment Tool**](https://www.microsoft.com/download/details.aspx?id=49117)
2. Run the downloaded file to extract `setup.exe` into an empty folder.
3. Download the `lsw_office_config.xml` from this repository and place it in the same folder.
4. Open the command prompt in that folder and run: `setup.exe /configure lsw_office_config.xml`

### ⚖️ Licensing & Homelab Testing
This project focuses exclusively on the extreme optimization of a virtual environment. It relies on the official evaluation versions provided by Microsoft:
* **Windows Server 2022 Evaluation** gives you a fully legal **180 days** to test the infrastructure *(with the possibility of extending the 180-day period up to 6 times, giving you nearly 3 years of testing)*.
* **Office Suite (Volume/LTSC)** offers a standard, free Grace Period immediately after installation.

**How to test this environment long-term?**
The recommended engineering practice for test environments (Proof of Concept) is to create a so-called "Golden Snapshot" in your hypervisor (Proxmox/VirtualBox) immediately after finishing the installation and WinApps configuration. When the evaluation period ends, you simply restore the machine to this clean, initial state and continue testing. This is a standard and fully legal workflow in homelabs.

If, after successful testing, you decide to move this environment into daily "production" – simply enter your legal product key in the settings and forget about snapshots!

### 🧰 Recommended Tools & Guides (For Beginners)
If you are just starting your homelab journey and want to build this setup from scratch, here are the essential tools and official guides you will need:

* **Virtual Machine Managers (Hypervisors):**
    * [Virtual Machine Manager (KVM/libvirt)](https://virt-manager.org/) - The native, lightning-fast hypervisor built right into the Linux kernel. **Highly recommended** as WinApps can automatically start/stop libvirt VMs!
    * [GNOME Boxes](https://apps.gnome.org/Boxes/) - The simplest, out-of-the-box VM manager often available by default on distros like Zorin OS or Ubuntu.
    * [Proxmox VE](https://www.proxmox.com/) - The industry standard for dedicated, bare-metal homelab servers.
    * [Oracle VirtualBox](https://www.virtualbox.org/) - Very easy to use if you are coming from a Windows host background.

* **Linux Integration (Seamless Mode):**
    * [WinApps Official Repository](https://github.com/winapps-org/winapps) - Step-by-step instructions on how to integrate Windows apps directly into your Linux app menu.

* **RDP Clients (Remote Desktop):**
    * [Remmina](https://remmina.org/) - A fantastic, user-friendly GUI client. Highly recommended if you just want to easily access the full Windows desktop!
    * [FreeRDP](https://www.freerdp.com/) - The powerful, command-line driven backend (required if you plan to use WinApps).
