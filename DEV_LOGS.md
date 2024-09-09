# 08-09-2024

I finally got flutter to work with my code, finally. Now there is A LOT of things I need to do. I don't know how to communicate between flutter and wayland stuff yet and I don't know if I want to create some sort of daemon to comunicate with the main interface.

## Things I need to figure out

### Window system

Can I create more than one window in flutter? If so, how would I control these windows and open them.
Can I create this widgets in an easily incorporable way to just put a folder in some place and run it?
I would love to have some sort of "plugin" (BAD WORD) to add some extra code with out having to completely compile everything from scratch,
just adding another project to the folder and register.

We want to share the same engine if possible to run multiple windows at the same time i guess, since the engine is pretty heavy. But will it be possible?

I've noticed that when calling the FlutterEngineSendWindowMetricsEvent they specify a window_id as well as a display_id implying we can have more than one display and more than one
### Passing control to dart

### Damage Regions

Incorporating damage regions wouldn't be the most complicated  thing in the world (famous last words) as I've already seen some code that does that.


#09-09-2024
    
I was thinking about how to get flutter to comunicate multiple windows, Apparently multiple "views" can be created from dart, however I do not know how this views are managed or how can I hook them up to a surface, pause them or make them disappear from the screen, maybe I could do something with that, but i'll need to implement a channel for those. I'll love to do it that way, but it seems unlikely that we are going to be able to create something composable that way. Composable meaning you can just add your files to a .config folder and it works.

For now I'm going to stick to my suboptimal implementation and isolate the engine instance from the rest of the application. That way I could make it a composable daemon by creating a bunch of engines running on parallel. One engine for each bundle in our .config file, and that'll make them all initialize at startup but render (or not) at the time the user directs them to do so.

I still don't know if we want a config json/yaml/anyother file of we want to give them a platform channel to communicate with the flutter engine to define the size of their window, the layer and so on.
Ideally i'll be easier for us to do it with a config file but to use a channel for dart i'll be ideal for more control over the behaviour directly inside your app/applet.

## Performance considerations.

I've been thinking about performance, and what I want to acheive, I want this panels to be around and to open as fast as possible whenever possible. And if it's possible i'll like the daemon to start before the compositor's config file is loaded to do a seemless transition between the login screen (sddm/gdm/etc) to a loading screen, to the desktop environment setup completely loaded. I'll also want it to feel as snappy as it can, opening and closing applets should NOT have any pauses, it should be as soon as you press the keybind with no delay.

for what I've measured now the craziest waiting time comes from either starting or initializing the flutter engine, of course I'm using an unstriped unopt engine, but still, I don't think there'll be that much difference between that and the "real" engine. If the engine takes too long to start, there is no easy way to fix this, all I can hope is that initializing the engine is the slow part, and running it doesn't take to much time. If it isn't the case, then we'll have to lose the composable part of this idea and handle views (If possible) inside a single engine. 


