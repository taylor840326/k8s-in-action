# BIOS 配置

## 性能

> 充分挖掘硬件性能（超频、多线程...）

* Turbo Mode：Enable
* Hyper-Threading [ALL]：Enable
* IO Directory Cache (IODC)：Auto
* UPI3：Enable
* Memory Frequency：Auto
* PCIe Max Read Request Size：Auto（系统内调控，不同设备不同上限）
* NUMA：Enabled
* Above 4G Decoding：Enabled （设置开启或关闭64位设备在大于4G地址空间的解码）
* CSM Support：Disabled （Compatibility Support Module）（UEFI）
* MMIO High Base：4T
* MMIO High Granularity Size：1024G
* PCIe ACSCTL：Disable

## 电力

> 不节能，保障最大电力供应

* Power Technology：Custom
* Power Performance Tuning：OS Controls EBP
* Optimized Power Mode：Disable
* SpeedStep (P-States)：Enable
* EIST PSD Function：HW_ALL
* Hardware P-States：Disable
* Enable Monitor MWAIT：Auto
* CPU C1 Auto Demotion：Auto
* CPU C6 Report：Enable
* Enhanced Halt State (C1E)：Enable
* Package C State：Auto
* PCIe ASPM Support (Global)：Disable （Active State Power Management）

## 安全

> 关闭安全策略保性能

* Enable SMX：Disable（Safer Mode Extensions）
* Data Scrambling for DDR5：Disable
* Trust Domain Extension (TDX)：Disabled
* KMS Security Policy：Disabled（Key Management Service）
* TPM Security Policy：Disabled （Trusted Platform Module）
* USB Security Policy：Disabled
* SGX Factory Reset：Disabled
* SW Guard Extensions (SGX)：Disabled

## 预取策略

* Hardware Prefetcher：Enable
* Adjacent Cache Prefetch：Enable
* DCU Streamer Prefetcher：Enable
* DCU IP Prefetcher：Enable
* LLC Prefetch：Enable
* KTI Prefetch：Auto

## 扩展

> 虚拟化相关扩展

* Intel Virtualization Technology：Disable
* SNC：Auto
* Intel VT for Directed I/O (VT-T-d)：Disable
* SR-IOV Support：Disabled

## 其他

* Patrol Scrub：Enable at End of POST
* BMC: 风扇转速最大
