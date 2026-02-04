# Reddit Post - For r/batocera and r/emulation

**Title:** [Guide] Fixed Error 1962 / Boot Issues Installing Batocera on Older Business PCs (Lenovo H50-50, similar hardware)

**Body:**

After 5 days of troubleshooting, I finally got Batocera working on a Lenovo H50-50 that kept giving Error 1962 (No operating system found). 

**The Problem:**
- Standard Rufus/Etcher flashing methods failed
- BIOS detected the drive but wouldn't boot
- Tried both UEFI and Legacy modes - nothing worked
- Even manually registering the EFI bootloader with efibootmgr didn't help

**The Solution:**
The H50-50's BIOS doesn't like Batocera's GPT/UEFI boot structure. I had to manually convert it to MBR/Legacy boot using SystemRescue, GParted, and dd commands.

**Full step-by-step guide here:** [your-github-url]

This likely affects other older business desktops from 2014-2016 era:
- Lenovo ThinkCentre M-series
- Dell OptiPlex 9020/7020/3020
- HP EliteDesk/ProDesk 800 G1/600 G1

If you're building a budget arcade cabinet with surplus office hardware and hitting boot issues, this might save you days of frustration.

The guide includes:
- Why standard methods fail
- Complete terminal commands (copy-paste ready)
- BIOS settings that actually work
- Troubleshooting section

Hope this helps someone else avoid the nightmare I just went through!

---

**Alternative shorter version for quick posting:**

**Title:** PSA: If Batocera won't boot on your older PC (Error 1962), try MBR/Legacy conversion

Successfully installed Batocera on a Lenovo H50-50 after 5 days of Error 1962 hell. Standard Rufus/Etcher methods don't work on some older business PCs - the BIOS hates GPT/UEFI boot.

Solution: Manual MBR/Legacy conversion using SystemRescue + GParted + dd commands.

Full guide: [your-github-url]

Likely helps with similar era ThinkCentres, OptiPlexes, EliteDesks if you're hitting boot issues.
