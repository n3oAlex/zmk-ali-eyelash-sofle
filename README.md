# zmk-ali-eyelash-sofle

ZMK firmware config for the AliExpress **Eyelash Sofle** split keyboard and its dongle.
Self-contained against stock ZMK (no seller modules), so bumping ZMK is a one-line change
in `config/west.yml`.

## Hardware

| Part | MCU | Extras |
| --- | --- | --- |
| Left half | nRF52840, nice!nano v2 compatible | nice!view display, horizontal EC11 roller (press = key), 7x WS2812 underglow, backlight |
| Right half | nRF52840, nice!nano v2 compatible | nice!view display, 5-way D-pad (four directions + press, wired as matrix keys), underglow, backlight |
| Dongle | nRF52840, seller's own PCB | 1.3" 128x64 I2C OLED (SH1106), battery with charger, power switch, reset button |

Pinouts live in `boards/shields/eyelash_sofle/`. All three parts build on the `nice_nano_v2`
board definition because the PCBs match it electrically (bootloader offsets, battery sense,
external power on P0.13).

## Modes

**Dongle mode (default).** The dongle is the split "central": it talks to the computer over
USB (or Bluetooth when unplugged and switched on) and both halves connect to it. Flash:

- `eyelash_sofle_dongle.uf2` to the dongle
- `eyelash_sofle_left_peripheral.uf2` to the left half
- `eyelash_sofle_right.uf2` to the right half

**Standalone mode (fallback).** No dongle; the left half is the central. Flash:

- `eyelash_sofle_left_central.uf2` to the left half
- `eyelash_sofle_right.uf2` to the right half

The two modes are not interchangeable. When switching, first flash `settings_reset.uf2` to
**every** part, then the mode's firmware. Otherwise the halves keep their old pairing and
never find the new central.

## Flashing

1. Double-tap the reset button on the part. A USB drive named `NICENANO` appears.
2. Copy the `.uf2` onto the drive. The part reboots by itself.

The `fn` layer also has `&bootloader` keys (on the `D` key for the left half, on `Y` for the
right half); they only reset the half the key is on. The dongle uses its reset button.

## First pairing in dongle mode

1. Flash `settings_reset.uf2` to the dongle, left and right. Wait a few seconds each.
2. Flash the dongle firmware, then the left peripheral firmware, then the right firmware.
3. Power on all three. The OLED shows both halves' battery levels once they connect.
4. Plug the dongle into USB, or press `fn` + `O` (`&out OUT_TOG`) to use Bluetooth and pair the
   dongle with a host like any ZMK keyboard.

## Keymap

`config/eyelash_sofle.keymap`, five layers: `root`, `move` (hold space), `fn`, `number`,
`game`. Roller: volume, press = play/pause; vertical scroll on `move`, horizontal scroll on
`fn`. D-pad: arrows, press = enter; mouse movement on `move`.

Recovery keys on `fn`: `D` = bootloader (left half), `Y` = bootloader (right half),
`U` = clear current Bluetooth profile, `I` = clear all profiles, `O` = toggle USB/Bluetooth
output, `P` = unlock ZMK Studio. Holding `Q` + `S` + `Z` for two seconds powers off all
parts; press each part's reset button to wake.

ZMK Studio is enabled on the dongle over USB (unlocked by default).

## Displays

- Dongle: layer name, modifiers, both halves' battery, USB/BLE profile, bongo cat. Provided by
  the `zmk-dongle-display` module; options in `config/eyelash_sofle_dongle.conf`.
- Halves: stock nice!view peripheral screen (own battery, connection state, artwork). In
  dongle mode the halves are peripherals and ZMK does not send them the active layer.

If the dongle OLED shows a garbled or shifted image, flash `eyelash_sofle_dongle_ssd1306.uf2`
instead. If it stays blank, the likely cause is the SCL pin: the PCB silkscreen suggests
P0.21, the nice!nano default is P0.20; change it in `eyelash_sofle_dongle.overlay`.

## Building

Every push builds all targets on GitHub Actions (`build.yaml` is the matrix); download the
`firmware` artifact from the run. `draw.yml` renders the keymap to `keymap-drawer/` on keymap
changes.

Locally, with Docker installed:

```sh
./build.sh                  # all targets -> firmware/*.uf2
./build.sh dongle right     # only targets whose artifact name matches
./build.sh --update         # refresh ZMK/modules after editing config/west.yml
```

## Config files

- `config/eyelash_sofle.conf`: shared by all parts.
- `config/eyelash_sofle_left.conf`, `config/eyelash_sofle_right.conf`: keyboard-half hardware (LEDs, roller, sleep); keep identical.
- `config/eyelash_sofle_dongle.conf`: dongle only (no sleep, OLED options, Studio).
- `config/west.yml`: ZMK version and modules.
- `config/eyelash_sofle.json`: physical layout for keymap tooling (keymap-drawer, keymap editor).

Origin: the seller's config at https://github.com/a741725193/zmk-sofle (also has the 3D models).
