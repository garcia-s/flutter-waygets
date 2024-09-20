

# How to run this stuff

To run this you need to install the following:

- wayland dev libraries
- egl dev libraries
- wayland-egl libraries
- clang and libc
- zig
- the flutter sdk
- an icudtl.dat file.

You'll also need a valid libflutter_engine.so and a flutter_embedder.h, either a debug one (which doesn't allow AOT) or a release one which will run in AOT

## Finding the debug files 

The debug (or rather non-AOT version of these files) can be downloaded in the link below by replacing the {FLUTTER_ENGINE} part with the hash of your flutter sdk engine) If you are unsure of where to find the hash for your version. It should be inside your sdkdirectory  in ```$FLUTTER_PATH/internal/engine.version``` The content of this __engine.version__ is a hash for your flutter engine version.

https://storage.googleapis.com/flutter_infra_release/flutter/FLUTTER_ENGINE/linux-x64/linux-x64-embedder.zip

## Finding the AOT version

You can download the other AOT capable engine from a project called flutter-embedded-linux (Shout-out to them, not that they need it). Which can be found in the following link. However you still have to match the engine version you are going to use to compile your app.

https://github.com/sony/flutter-embedded-linux/releases/latest


## Building the damn embedder

If you have everything you need to build it should be as easy as editing the build.zig file with the path to your libflutter_engine.so and flutter_embedder.h and running __zig build__. If you are not familiarized with zig, no problem, the output should be in __./zig-out/bin/yarad__.

If something fails it's probably my fault and I forgot to include a library in the list. 

## Creating a project

You can just create a normal project and code it like you'll normally would with  ```flutter create {name}```. And you can run it like any other app until you are ready to assemble and put it somewhere to try the embedder.

## Compiling the flutter app(s)

Once you are done coding and want to compile your code you'll need to assemble your app. Now, this is super-obscure because the __flutter build aot__ has been deleted. if you are running in AOT you'll need to use the following command:

```
flutter assemble -v -dBuildMode="release" \
    -dTargetPlatform="linux-x64" \
    --output="./build/release" release_bundle_linux-x64_assets 
```

## Putting things in their place.

So that __yarad__ file we talk about before, that's your the thing you need to run your app(s). This, for now, receives only one argument, the argumentis a path to a folder containing the __outputs__ of the flutter projects you wish to run. Inside this you can put your project and it should look like this

```
    yarad
        ↳ project_name
            ↳ flutter_assets
            ↳ icudtl.dat
            ↳ config.json
```

## Finding the icudtl

You can look for this folder inside of your Flutter SDK cache folder. it should be in ```$FLUTTER_PATH/cache/artifacts/engine/linux-x64/icudtl.dat```
This will create your libapp.so which this embedder is capable of running, along with other necessary files.

If you are running on JIT, you can just ```flutter build bundle```


## the config.json file 

This is provided in the root of the project and you can just copy it your project folder and that's it.


## Run Run Run

Now you can execute .path/to/exe/yarad ./path/to/projects/folder and it should appear in your screen.


