
# Learning wayland

Ok now that I have the build pipeline sort of working and the linting working completely, I can now try to understand layer shell and flutter's embedder ABI, this is going to be hard, but I think I can manage to research and write some code


## Research about Wayland layer shell

Things I think I know: 

- Wayland layer shell is not a standard, is something implemented by some compositors.
- The wayland client still need to give you a real display for you to use the layer shell.
- Rendering things is not handled by the server, it's actually handled by the client and then pixel data is sent to the server to display.


Things I need to research:


- How to get the "wlr-layer-shell-unstable-v1-protocol.h"?

Answer: Turns out, you don't "get" the damn file. You use something called "wayland-scanner" to generate the file, with the xml protocol definition. So there is NO FILE, you just need the xml and you generate at build time. I wish this was written somewhere in ALL CAPS and red lettering. I've spent all day looking for that damn file.

Here is the command so I don't forget: 

```
wayland-scanner client-header /usr/share/wlr-protocols/unstable/wlr-layer-shell-unstable-v1.xml wlr-layer-shell-unstable-v1-protocol.h
```

## Research about Flutter

Things I think I know:
Things I need to research:

## Doubts about the software design

One of my biggest concerns is, how do I manage multiple windows from flutter to the display? I don't want to create new widgets and force people to use them for the applets, and I also don't want to create daemon, but what would be a decent
