<# :
@echo off
color 0B
title LSW OPTIMIZER
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0' -Raw) -replace '(?s)^\<#.*?\n#\>','')"
exit /b
#>
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit }

function Execute-Task {
    param ( [string]$Description, [scriptblock]$CodeBlock )
    Write-Host "[*] Deploying: $Description... " -NoNewline
    try { Invoke-Command -ScriptBlock $CodeBlock -ErrorAction Stop; Write-Host "[COMPLETED]" -ForegroundColor Green } 
    catch { Write-Host "[FAILED]" -ForegroundColor Red }
}

$Modules = @(
    @{ Name = "Enable Remote Desktop Connections"; Enabled = $true; Ram = 0; Desc = "Modifies fDenyTSConnections registry key."; Code = { Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 } },
    @{ Name = "Configure Firewall Inbound Rules"; Enabled = $true; Ram = 0; Desc = "Authorizes Remote Desktop traffic through Firewall."; Code = { Enable-NetFirewallRule -DisplayGroup "Remote Desktop" | Out-Null } },
    @{ Name = "Disable Network Level Auth (NLA)"; Enabled = $true; Ram = 0; Desc = "Ensures compatibility with Linux-based RDP clients."; Code = { Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0 } },
    @{ Name = "Enforce Single Session Limit"; Enabled = $true; Ram = 0; Desc = "Restricts concurrent user sessions."; Code = { Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name "fSingleSessionPerUser" -Value 1 } },
    @{ Name = "Enable RemoteApp Mode"; Enabled = $true; Ram = 0; Desc = "Permits application-level window streaming."; Code = { $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSAppAllowList"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "fDisabledAllowList" -Value 1 -Type DWord } },
    @{ Name = "Force .NET Framework Compilation"; Enabled = $true; Ram = 0; Desc = "Executes NGen to eliminate background CPU spikes."; Code = { $n="C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe"; if(Test-Path $n){Start-Process -FilePath $n -ArgumentList "executeQueuedItems" -Wait -WindowStyle Hidden} } },
    @{ Name = "Deploy Memory Purge Schedule (30s)"; Enabled = $true; Ram = 100; Desc = "Installs Mem Reduct and creates 30s automated loop."; Code = { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri "https://github.com/henrypp/memreduct/releases/download/v.3.4/memreduct-3.4-setup.exe" -OutFile "C:\mr.exe"; Start-Process "C:\mr.exe" -ArgumentList "/S /D=C:\memreduct" -NoNewWindow; Start-Sleep 5; Stop-Process -Name "memreduct","mr" -Force -ErrorAction SilentlyContinue; Remove-Item "C:\mr.exe" -Force -ErrorAction SilentlyContinue; Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "memreduct" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "memreduct" -ErrorAction SilentlyContinue; Set-Content -Path "C:\memreduct\cl.bat" -Value "@echo off`n:L`nstart """" `"C:\memreduct\memreduct.exe`" -clean`ntimeout /t 30 /nobreak >nul`ntaskkill /F /IM memreduct.exe >nul 2>&1`ngoto L" -Encoding Ascii -Force; $v="Set W=CreateObject(`"WScript.Shell`")`nW.Run Chr(34)&`"C:\memreduct\cl.bat`"&Chr(34),0`nSet W=Nothing"; Set-Content -Path "C:\memreduct\cl.vbs" -Value $v -Encoding Ascii -Force; & schtasks /create /tn "LSW_MemReduct" /tr "wscript.exe C:\memreduct\cl.vbs" /sc onlogon /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /F | Out-Null; Start-Process "wscript.exe" -ArgumentList "C:\memreduct\cl.vbs" -WindowStyle Hidden } },
    @{ Name = "Enable Automatic License Rearm"; Enabled = $true; Ram = 0; Desc = "Background task to renew Server Eval automatically."; Code = { $s="`$l=Get-WmiObject SoftwareLicensingProduct|Where-Object{`$_.Name -match `"Server`" -and `$_.GracePeriodRemaining -gt 0}|Select-Object -First 1`nif(`$l -and `$l.GracePeriodRemaining -lt 14400){cscript.exe `$env:windir\system32\slmgr.vbs /rearm;shutdown.exe /r /t 60}"; Set-Content -Path "C:\LSW_Rearm.ps1" -Value $s -Encoding Ascii -Force; $a=New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\LSW_Rearm.ps1"; $t=New-ScheduledTaskTrigger -Daily -At 12:00PM; Register-ScheduledTask -Action $a -Trigger $t -TaskName "LSW_AutoRearm" -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Force|Out-Null } },
    @{ Name = "Optimize Visual Effects (Performance)"; Enabled = $true; Ram = 10; Desc = "Disables UI shadows and transparencies."; Code = { $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "VisualFXSetting" -Value 2 -Type DWord } },
    @{ Name = "Disable Lock Screen Rendering"; Enabled = $true; Ram = 10; Desc = "Prevents LogonUI from rendering the background image."; Code = { $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "NoLockScreen" -Value 1 -Type DWord } },
    @{ Name = "Eradicate Windows Defender"; Enabled = $true; Ram = 150; Desc = "Uninstalls the native Antivirus role completely."; Code = { Uninstall-WindowsFeature -Name Windows-Defender -Remove -WarningAction SilentlyContinue|Out-Null } },
    @{ Name = "Disable Server Manager Autostart"; Enabled = $true; Ram = 80; Desc = "Prevents Server Manager initialization upon logon."; Code = { $p="HKLM:\SOFTWARE\Microsoft\ServerManager"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "DoNotOpenServerManagerAtLogon" -Value 1 -Type DWord; Get-ScheduledTask -TaskName "ServerManager" -TaskPath "\Microsoft\Windows\Server Manager\" -ErrorAction SilentlyContinue|Disable-ScheduledTask -ErrorAction SilentlyContinue|Out-Null } },
    @{ Name = "Suppress Edge Background Activity"; Enabled = $true; Ram = 20; Desc = "Terminates Microsoft Edge updater background tasks."; Code = { $e=Get-Service -Name "*edge*" -ErrorAction SilentlyContinue; if($e){$e|Stop-Service -Force -ErrorAction SilentlyContinue; $e|Set-Service -StartupType Disabled -ErrorAction SilentlyContinue}; Get-ScheduledTask -ErrorAction SilentlyContinue|Where-Object{$_.TaskName -match "Edge"}|Disable-ScheduledTask -ErrorAction SilentlyContinue|Out-Null } },
    @{ Name = "Disable Windows Search & Cortana"; Enabled = $true; Ram = 10; Desc = "Injects policies to prevent SearchApp execution."; Code = { $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "AllowCortana" -Value 0 -Type DWord; Set-ItemProperty -Path $p -Name "DisableWebSearch" -Value 1 -Type DWord; $p2="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; if(!(Test-Path $p2)){New-Item -Path $p2 -Force|Out-Null}; Set-ItemProperty -Path $p2 -Name "BingSearchEnabled" -Value 0 -Type DWord } },
    @{ Name = "Hide Taskbar Search Box"; Enabled = $true; Ram = 5; Desc = "Removes the search UI element from the taskbar."; Code = { $p="HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "SearchboxTaskbarMode" -Value 0 -Type DWord } },
    @{ Name = "Disable Spooler (Print Spooler)"; Enabled = $true; Ram = 15; Desc = "Disable if physical printing is not required."; Code = { & sc.exe config Spooler start= disabled *>$null; & net.exe stop Spooler /y *>$null } },
    @{ Name = "Disable WSearch (Windows Search)"; Enabled = $true; Ram = 40; Desc = "Terminates file indexing to conserve IOPS."; Code = { & sc.exe config WSearch start= disabled *>$null; & net.exe stop WSearch /y *>$null } },
    @{ Name = "Disable SysMain (Superfetch)"; Enabled = $true; Ram = 20; Desc = "Disables application preloading (suggested for VM)."; Code = { & sc.exe config SysMain start= disabled *>$null; & net.exe stop SysMain /y *>$null } },
    @{ Name = "Disable DiagTrack (Telemetry)"; Enabled = $true; Ram = 15; Desc = "Halts diagnostic data transmission."; Code = { & sc.exe config DiagTrack start= disabled *>$null; & net.exe stop DiagTrack /y *>$null } },
    @{ Name = "Disable WerSvc (Error Reporting)"; Enabled = $true; Ram = 15; Desc = "Disables the Windows Error Reporting mechanism."; Code = { & sc.exe config WerSvc start= disabled *>$null; & net.exe stop WerSvc /y *>$null } },
    @{ Name = "Disable wuauserv (Windows Update)"; Enabled = $true; Ram = 15; Desc = "Halts the primary Windows Update engine."; Code = { & sc.exe config wuauserv start= disabled *>$null; & net.exe stop wuauserv /y *>$null } },
    @{ Name = "Disable WaaSMedicSvc (Update Medic)"; Enabled = $true; Ram = 10; Desc = "Prevents Windows Update from repairing itself."; Code = { & sc.exe config WaaSMedicSvc start= disabled *>$null; & net.exe stop WaaSMedicSvc /y *>$null } },
    @{ Name = "Disable UsoSvc (Update Orchestrator)"; Enabled = $true; Ram = 10; Desc = "Disables update scheduling and coordination."; Code = { & sc.exe config UsoSvc start= disabled *>$null; & net.exe stop UsoSvc /y *>$null } },
    @{ Name = "Disable TabletInputService"; Enabled = $true; Ram = 5; Desc = "Disables touch keyboard and handwriting panel."; Code = { & sc.exe config TabletInputService start= disabled *>$null; & net.exe stop TabletInputService /y *>$null } },
    @{ Name = "Disable TrkWks (Link Tracking)"; Enabled = $true; Ram = 5; Desc = "Disables distributed link tracking across networks."; Code = { & sc.exe config TrkWks start= disabled *>$null; & net.exe stop TrkWks /y *>$null } },
    @{ Name = "Disable RemoteRegistry"; Enabled = $true; Ram = 5; Desc = "Prevents remote modification of the system registry."; Code = { & sc.exe config RemoteRegistry start= disabled *>$null; & net.exe stop RemoteRegistry /y *>$null } },
    @{ Name = "Disable MapsBroker"; Enabled = $true; Ram = 5; Desc = "Disables downloaded maps management."; Code = { & sc.exe config MapsBroker start= disabled *>$null; & net.exe stop MapsBroker /y *>$null } },
    @{ Name = "Disable msdtc (Transaction Coordinator)"; Enabled = $true; Ram = 5; Desc = "Disables distributed network transaction tracking."; Code = { & sc.exe config msdtc start= disabled *>$null; & net.exe stop msdtc /y *>$null } },
    @{ Name = "Disable W32Time (Windows Time)"; Enabled = $true; Ram = 5; Desc = "Relies on Hypervisor for time synchronization."; Code = { & sc.exe config W32Time start= disabled *>$null; & net.exe stop W32Time /y *>$null } },
    @{ Name = "Disable Themes"; Enabled = $true; Ram = 5; Desc = "Forces classic window borders and lowers overhead."; Code = { & sc.exe config Themes start= disabled *>$null; & net.exe stop Themes /y *>$null } },
    @{ Name = "Disable Schedule (Task Scheduler)"; Enabled = $true; Ram = 5; Desc = "Deactivates non-critical scheduled background tasks."; Code = { & sc.exe config Schedule start= disabled *>$null; & net.exe stop Schedule /y *>$null } },
    @{ Name = "Disable SharedAccess (ICS)"; Enabled = $true; Ram = 5; Desc = "Disables Internet Connection Sharing routing."; Code = { & sc.exe config SharedAccess start= disabled *>$null; & net.exe stop SharedAccess /y *>$null } },
    @{ Name = "Disable WinHttpAutoProxySvc"; Enabled = $true; Ram = 5; Desc = "Disables web proxy auto-discovery."; Code = { & sc.exe config WinHttpAutoProxySvc start= disabled *>$null; & net.exe stop WinHttpAutoProxySvc /y *>$null } },
    @{ Name = "Terminate UI & Automate LogonUI Killer"; Enabled = $true; Ram = 130; Desc = "Kills active UI and installs background LogonUI remover."; Code = {
        $p = @("ServerManager","SearchApp","StartMenuExperienceHost","TextInputHost","RuntimeBroker","ctfmon","ApplicationFrameHost","mip","TiWorker","LogonUI","MicrosoftEdgeUpdate")
        foreach ($i in $p) { Stop-Process -Name $i -Force -ErrorAction SilentlyContinue }
        Set-Content -Path "C:\L_Kill.bat" -Value "@echo off`n:L`ntaskkill /F /IM LogonUI.exe >nul 2>&1`ntimeout /t 5 /nobreak >nul`ngoto L" -Encoding Ascii -Force
        Set-Content -Path "C:\L_Kill.vbs" -Value "Set W=CreateObject(`"WScript.Shell`")`nW.Run Chr(34)&`"C:\L_Kill.bat`"&Chr(34),0`nSet W=Nothing" -Encoding Ascii -Force
        & schtasks /create /tn "LSW_LogonKiller" /tr "wscript.exe C:\L_Kill.vbs" /sc onlogon /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /F | Out-Null
        Start-Process "wscript.exe" -ArgumentList "C:\L_Kill.vbs" -WindowStyle Hidden
    }},
    @{ Name = "Disable Application Experience Tasks"; Enabled = $true; Ram = 15; Desc = "Terminates CompatTelRunner and telemetry schedules."; Code = { Stop-Process -Name "CompatTelRunner" -Force -ErrorAction SilentlyContinue; Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" -ErrorAction SilentlyContinue|Disable-ScheduledTask -ErrorAction SilentlyContinue|Out-Null } },
    @{ Name = "Consolidate Service Hosts (4194304)"; Enabled = $true; Ram = 100; Desc = "Bundles services into fewer svchost.exe processes."; Code = { cmd.exe /c 'reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 4194304 /f' *>$null } },
    @{ Name = "Disable Memory Page Combining"; Enabled = $true; Ram = 10; Desc = "Modifies DisablePageCombining to reduce CPU overhead."; Code = { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePageCombining" -Value 0 -Type DWord } },
    @{ Name = "Degrade RDP Color Depth (16-bit)"; Enabled = $true; Ram = 20; Desc = "Lowers bandwidth and visual overhead for DWM.exe."; Code = { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "ColorDepth" -Value 3 -Type DWord; $p="HKLM:\SOFTWARE\Policies\Citrix\ICAPolicies"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "MaxColorDepth" -Value 16 -Type DWord } },
    @{ Name = "Restrict Kernel Memory Pools"; Enabled = $true; Ram = 40; Desc = "Imposes constraints on Paged/NonPaged pools."; Code = { $m="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Set-ItemProperty -Path $m -Name "PoolUsageMaximum" -Value 40 -Type DWord; Set-ItemProperty -Path $m -Name "NonPagedPoolSize" -Value 192 -Type DWord; Set-ItemProperty -Path $m -Name "PagedPoolSize" -Value 192 -Type DWord; Set-ItemProperty -Path $m -Name "SessionViewSize" -Value 16 -Type DWord; Set-ItemProperty -Path $m -Name "SessionPoolSize" -Value 16 -Type DWord; Set-ItemProperty -Path $m -Name "DisablePagingExecutive" -Value 0 -Type DWord } },
    @{ Name = "Disable Hibernation"; Enabled = $true; Ram = 0; Desc = "Deletes hiberfil.sys to reclaim storage capacity."; Code = { powercfg -h off|Out-Null } },
    @{ Name = "Enforce Static Pagefile (1024 MB)"; Enabled = $true; Ram = 0; Desc = "Restricts dynamic swap file expansion on root drive."; Code = { $s=Get-WmiObject Win32_ComputerSystem; $s.AutomaticManagedPagefile=$false; $s.Put()|Out-Null; Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name="C:\pagefile.sys";InitialSize=1024;MaximumSize=1024} -ErrorAction SilentlyContinue|Out-Null } },
    @{ Name = "Disable Power Throttling"; Enabled = $true; Ram = 0; Desc = "Forces constant high-performance state for CPU cycles."; Code = { $p="HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name "PowerThrottlingOff" -Value 1 -Type DWord } },
    @{ Name = "Enable Headless Shell (Replaces GUI)"; Enabled = $false; Ram = 80; Desc = "WARNING: Removes standard Desktop. Loads CMD only."; Code = { Set-Content -Path "C:\shell.bat" -Value "@echo off`ncmd.exe" -Encoding Ascii -Force; $w="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"; Set-ItemProperty -Path $w -Name "Shell" -Value "C:\shell.bat" -Type String; Set-ItemProperty -Path $w -Name "AutoRestartShell" -Value 0 -Type DWord } },
    @{ Name = "Enable Audio Services (Optional)"; Enabled = $false; Ram = -20; Desc = "Activates Audiosrv for sound output requirements."; Code = { Set-Service -Name "Audiosrv" -StartupType Automatic; Start-Service -Name "Audiosrv" -ErrorAction SilentlyContinue } },
    @{ Name = "Execute DISM Component Cleanup"; Enabled = $false; Ram = 0; Desc = "Purges obsolete update files. May require 10 minutes."; Code = { DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase|Out-Null } }
)

function Show-InteractiveMenu {
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 32)
    [Console]::CursorVisible = $false
    $Index=0; $ExitLoop=$false; $VisibleRows=23; $ViewStart=0

    while (-not $ExitLoop) {
        if ($Index -ge ($ViewStart + $VisibleRows)) { $ViewStart = $Index - $VisibleRows + 1 }
        if ($Index -lt $ViewStart) { $ViewStart = $Index }

        [Console]::SetCursorPosition(0,0)
        Write-Host "=======================================================================================================================" -ForegroundColor Cyan
        Write-Host "   LSW OPTIMIZER - ADVANCED CONFIGURATION MATRIX                                                                       " -ForegroundColor White
        Write-Host "=======================================================================================================================" -ForegroundColor Cyan
        Write-Host " CONTROLS: [Up/Down] Navigate | [Space] Toggle | [Enter] Execute Deployment                                            " -ForegroundColor Yellow
        Write-Host "=======================================================================================================================" -ForegroundColor DarkGray

        $EstimatedRam = 1100
        for ($i=0; $i -lt $Modules.Count; $i++) { if ($Modules[$i].Enabled) { $EstimatedRam -= $Modules[$i].Ram } }

        for ($i=$ViewStart; $i -lt [math]::Min($Modules.Count, $ViewStart + $VisibleRows); $i++) {
            $Check = if ($Modules[$i].Enabled) { "[X]" } else { "[ ]" }
            $RamFmt = if ($Modules[$i].Ram -lt 0) { "+$([math]::abs($Modules[$i].Ram)) MB" } else { "-$($Modules[$i].Ram) MB" }
            $ModName = "{0,-47}" -f $Modules[$i].Name
            $RamStr = "{0,9}" -f $RamFmt
            $Desc = $Modules[$i].Desc

            $Prefix = " $Check $ModName $RamStr | "
            if ($i -eq $Index) { $Prefix = ">$Check $ModName $RamStr | " }
            
            $RemainingSpace = 119 - $Prefix.Length
            if ($Desc.Length -gt $RemainingSpace) { $Desc = $Desc.Substring(0, $RemainingSpace) }
            $PaddedDesc = $Desc.PadRight($RemainingSpace, ' ')

            if ($i -eq $Index) {
                Write-Host $Prefix -ForegroundColor Black -BackgroundColor Cyan -NoNewline
                Write-Host $PaddedDesc -ForegroundColor Yellow -BackgroundColor Black
            } else {
                if ($Modules[$i].Enabled) { Write-Host $Prefix -ForegroundColor Green -NoNewline } 
                else { Write-Host $Prefix -ForegroundColor Gray -NoNewline }
                Write-Host $PaddedDesc -ForegroundColor DarkGray -BackgroundColor Black
            }
        }

        $PaddingRows = $VisibleRows - ([math]::Min($Modules.Count, $ViewStart + $VisibleRows) - $ViewStart)
        for ($k=0; $k -lt $PaddingRows; $k++) { Write-Host (" " * 119) -BackgroundColor Black }
        if ($EstimatedRam -lt 140) { $EstimatedRam = 140 }

        Write-Host "=======================================================================================================================" -ForegroundColor Cyan
        $Footer = "   INDEX: [$($Index + 1)/$($Modules.Count)] | SCROLL DOWN FOR ADDITIONAL PARAMETERS | ESTIMATED RAM OFFSET: ~ $EstimatedRam MB "
        Write-Host $Footer.PadRight(119, ' ') -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "=======================================================================================================================" -ForegroundColor Cyan

        $Key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($Key.KeyDown) {
            if ($Key.VirtualKeyCode -eq 38 -and $Index -gt 0) { $Index-- }
            elseif ($Key.VirtualKeyCode -eq 40 -and $Index -lt ($Modules.Count - 1)) { $Index++ }
            elseif ($Key.Character -eq ' ') { $Modules[$Index].Enabled = -not $Modules[$Index].Enabled }
            elseif ($Key.VirtualKeyCode -eq 13) { $ExitLoop = $true }
        }
    }
    [Console]::CursorVisible = $true
}

Clear-Host; Show-InteractiveMenu; Clear-Host
Write-Host "==================================================" -ForegroundColor Green
Write-Host " INITIATING DEPLOYMENT SEQUENCE..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
foreach ($module in $Modules) { if ($module.Enabled) { Execute-Task $module.Name $module.Code } }
if ((Read-Host "`nDEPLOYMENT COMPLETED. Reboot now? (Y/N)") -match "^[YyZzTt]$") { Restart-Computer -Force }
