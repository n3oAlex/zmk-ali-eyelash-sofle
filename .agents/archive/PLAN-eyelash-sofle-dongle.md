# PLAN: Clean Eyelash Sofle zmk-config with dongle
Status: done

## Summary
New self-contained zmk-config for the AliExpress "Eyelash Sofle" split keyboard
(left: nice!view + horizontal EC11 roller; right: nice!view + 5-key D-pad wired as
matrix keys) plus a seller dongle (nRF52840 nice!nano-compatible board + 1.3" I2C OLED,
likely SH1106). Replaces n3oAlex/zmk-ali-sofle, which was the seller's repo
(a741725193/zmk-sofle) plus 6 keymap-editor commits.

## Decisions (grilling session 2026-09-10)
- Stock ZMK v0.3.0 (latest release), no seller module, no cormoran fork. Bump later.
- Hardware as shields on `nice_nano_v2` (PCB is electrically a nice!nano v2 clone).
- Dongle mode is the daily driver: dongle = central (+Studio, locking off),
  both halves peripherals. Standalone fallback (left central) also built.
- Keymap ported as-is + recovery keys on fn layer + Q+S+Z soft-off combo.
  Roller: volume / play-pause; scroll on move layer, horizontal scroll on fn.
- Dongle display: englmaxi/zmk-dongle-display (v0.3 branch). SH1106 first, SSD1306 fallback build.
- Halves: stock nice_view shield (peripheral screen: battery, connection, art).
- Dongle: USB when plugged, BLE on battery (ZMK default), never deep-sleeps.
- CI: vendored copy of ZMK's v0.3.0 build-user-config workflow with Node 24 actions (upstream v0.3.x still uses checkout@v4; ZMK main's workflow breaks on v0.3.0) + keymap-drawer. Local: build.sh (Docker).
- Old repo archived on GitHub after all three devices verified.

## Open
- [x] Dongle MCU board photo: custom seller PCB; silkscreen says SDA=P0.17, SCL=P0.21 (used; verify on hardware).
- [x] Dongle bootloader: UF2 drive works.
- [x] SH1106 confirmed on hardware.

## TODO
- [x] Audit old repo / upstream / branches
- [x] Shields: eyelash_sofle_left/right/dongle
- [x] config: west.yml, .conf, keymap, json
- [x] build.yaml + workflows + keymap-drawer config
- [x] build.sh (Docker) + local build of all targets
- [x] README (hardware, flashing, pairing procedure)
- [x] Create GitHub repo n3oAlex/zmk-ali-eyelash-sofle, push, CI green (run 34531213570, no annotations)
- [x] Flash + verify on hardware (user): all three parts work in dongle mode, OLED works with SH1106 + SCL P0.20
- [x] Archive old repo

## Verification
- Local Docker build (build.sh) of all 6 targets passes on 2026-09-10; only warnings are ZMK's standard nice!nano peripheral USB notice.
- Verified on hardware 2026-09-10 (user).

## Touched files
boards/shields/eyelash_sofle/*, config/*, build.yaml, build.sh, .github/workflows/*,
keymap_drawer.config.yaml, README.md, zephyr/module.yml
