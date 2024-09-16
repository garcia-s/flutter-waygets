
# Flutter embedder for creating widgets for wlroots based compositors (Or anything with wlr-layer-shell) 

This is a "zig" flutter embedder to create flutter widgets for wlr-layer-shell. However this is currently in the VERY early stages of development and should NOT be used by, well, anyone.

## BEHOLD The underwhelming power of poorly made screencaptures

![flutter_gui](./assets/out.gif)

![flutter_gui2](./assets/out2.gif)



## WHY FLUTTER ??

Well, I like flutter. GDK, Iced, GLFW, QT and so on, they are cool, and they are very useful and fast. However they are HARD as F*** compared with something like flutter or even Android development (but not IOS because f*** Swift). My goal is to lower the bar for people like me. So normal people (who aren't C Chads with 10+years of experience) can build their GUIs in a higher level language, if they are willing to pay the (performace) price. An alternative to these tools, and hopefully a good one.

Also, animations on flutter are SO EASY, that you can create something really neet with it without that.


## How to run

Instructions for running this madness can be found [here](./instructions.md). Consider this is on VERY early stages of development and I can't guarantee this to be up to date.

## Performance and design considerations 

Flutter has kinda good performance, but if we can't implement multi-window support it'll be like 12mb of ram and spinning 6 threads just to run a menu, if this is something like a pop up menu, it'll probably not be worth it. But for complex menus and embedded semi complex applets it'll be worth it and I think it'll be better than bash+rofi or eww-wayland (Not that those tools are bad, they are great btw, is what I use every day).

## TODOS:

### We are missing the following things to be sort of working with a semi-usable project

-Keyboard input
-Proper engine disposal control
-Method channels to intra-embedder comunication between apps
-A Dbus implementation to allow outside applications to send events to the embedder and viceversa


### Things we might need to add but are not top priority
    
- A way to comunicate with hyprland workspaces
- Support for other input devices
- A Display manager version ???? I'll definitely love to be able to do a whlode DE in just flutter
- Multi-window support ????? This would be SO GOOD to implement, however I have a single idea of how this could be implemented, if I can't do it that way then I'm completely out of ideas here.
    




