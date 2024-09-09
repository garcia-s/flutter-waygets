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

Incorporating damage regions wouldn't be the most complicated  thing in the world (famous last words) as I've already seen some code that does that, 
