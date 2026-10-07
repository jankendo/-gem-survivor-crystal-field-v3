# Physical iOS gate

**NOT YET VERIFIED ON REAL DEVICE** for every item below. Do not fill estimated measurements as observations.

Record iPhone/iPad model, iOS version, signed local build SHA, seed, battery %, ambient temperature, profile and instrumentation.

- Sustained 15 minutes and sustained 30 minutes.
- Average FPS, frame p95 and p99, peak resident memory.
- Thermal state transitions and recovery.
- Low Power Mode on/off; confirm only effective presentation changes.
- Battery drain with controlled brightness/temperature/network settings.
- Touch latency, dynamic joystick, multitouch, release/cancel, every menu/control reachable without keyboard.
- Landscape orientation, notch, safe-area and iPad resize.
- Ultra profile transition retains font sizes, control rects, critical visuals and gameplay results.
- Clear → end / Endless → pause → result → retry flows.
- User signing through Xcode/AltStore/Sideloadly; unsigned archive alone cannot install.

Use OS/GPU profiling on actual hardware. Headless, simulator and llvmpipe measurements do not substitute for this gate.
