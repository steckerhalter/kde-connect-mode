# kde-connect-mode.el

An Emacs mode to write directly to a KDE Connect device (e.g. your phone) via the KDE Connect Remote Keyboard.

---

## Features

- **Live D-Bus Streaming:** Forwards every key instantly to your target device.
- **Dedicated Scratchpad:** Run `M-x kde-connect-scratchpad` to instantly open a clean drafting buffer.
- **Minor Mode:** Toggle `M-x kde-connect-mode` on or off in any existing Emacs buffer.

---

## Prerequisites

1. **Emacs** (version 26.1 or newer)
2. **KDE Connect** installed and paired with your mobile device (e.g., Android running the KDE Connect app).
3. **`qdbus6`** available in your system `$PATH` (standard with Qt6 / KDE Plasma 6).
4. **Android IME:** Make sure **KDE Connect Remote Keyboard** is enabled and set as your active input method on your phone when typing.

---

## Installation

1. Download or place `kde-connect-mode.el` into your Emacs load-path (e.g., `~/.emacs.d/lisp/`).
2. Add the following to your `init.el` or configuration file:

```elisp
(add-to-list 'load-path "~/.emacs.d/lisp/")
(require 'kde-connect-mode)

```

---

## Configuration & Usage

You can customize your target device name (as listed in KDE Connect) by setting `kde-connect-device-name`:

    (setq kde-connect-device-name "Pixel 6a")

### Commands

- **`M-x kde-connect-scratchpad`**: Opens a dedicated distraction-free buffer (`*KDE Connect D-Bus*`) with the mode active.
- **`M-x kde-connect-mode`**: Toggles live key streaming in your current buffer.

### Keybindings within the Mode

| Key | Action |
| :--- | :--- |
| **Normal typing** | Forwards characters live to your phone via D-Bus. |
| `C-c C-c` | Exits `kde-connect-mode` and closes the scratchpad window. |

---

## Author

Reto Hubmann ([@steckerhalter](https://github.com/steckerhalter))

## License

Distributed under the MIT License.
