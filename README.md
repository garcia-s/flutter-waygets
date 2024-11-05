
# Flutter embedder to create widgets, panels and menus in wlroots based compositors (Or anything with wlr-layer-shell really).

## This project is the base for the YARA Desktop environment, a Hyprland based Desktop Environment made with flutter tools. You can find that project [here](https://github.com/garcia-s/yara_shell)

This is a "zig" flutter embedder to create flutter widgets for wlr-layer-shell. However this is currently in the VERY early stages of development and should NOT be used by, well, anyone.

## Conceptual screenshots

![flutter_gui](./assets/out.gif)
![flutter_gui2](./assets/out2.gif)

## WHY FLUTTER ??

Well, I like flutter. GDK, Iced, GLFW, QT and so on, they are cool, and they are very useful and fast. However they are HARD to use compared with something like flutter or even Android development. My goal is to lower the bar for people like me. So normal people (who aren't C Chads with 10+years of experience) can build their GUIs in a higher level language, if they are willing to pay the (performace) price. An alternative to these tools, and hopefully a good one.

Also, animations on flutter are SO EASY, that you can create something really amazing with it, without wasting half of your life.

## How to run (These instructions are currently outdated)

Instructions for running this madness can be found [here](./instructions.md). Consider this is on VERY early stages of development and I can't guarantee this to be up to date.

## Current features (as of 03-10-2024)

- Multi-windows support (as in Creating multiple wayland surfaces)
- Simple pointer events (5 mouse buttons and things like long press)
- Flutter rendering directly into egl-wayland surfaces

##TODOS:

### High-prio

- Design a real positioning, layering margin API,
- Steal GLFW or GDK keyboard handling (we really need this asap)
- Define layer names for panels
- Add a translation layer for the surface scroll

