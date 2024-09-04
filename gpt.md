The Flutter Embedder ABI (Application Binary Interface) is an interface that allows you to embed Flutter applications into custom platforms.
This ABI is key to how the Flutter engine interacts with the host platform. Here's a breakdown of how it is structured and works:

1. Core Components
The Flutter Embedder ABI revolves around a few key components:

Flutter Engine: The core engine that runs the Dart code, handles rendering, and manages plugins.
Embedder: The custom code that integrates the Flutter engine with the host platform. This code is responsible for handling input, rendering surfaces, and more.
Dart VM: Embedded within the Flutter Engine, it executes the Dart code.
Platform Channels: Mechanism for communication between Dart code and the platform-specific code (host).

2. Embedder API
The ABI is provided through the Embedder API (flutter_embedder.h), which exposes the necessary functions and structures to embed Flutter into a custom shell.

Key functions include:

FlutterEngineRun: Starts the Flutter engine.
FlutterEngineShutdown: Shuts down the engine.
FlutterEngineSendWindowMetricsEvent: Sends window size and DPI information to the engine.
FlutterEngineSendPointerEvent: Sends pointer events (touch, mouse) to the engine.
FlutterEngineSendPlatformMessage: Facilitates platform channel communication.
FlutterEngineRunTask: Runs tasks that the Flutter engine schedules on a platform-specific task runner.

3. Rendering
The embedder is responsible for providing a rendering surface to the Flutter engine:

The engine renders onto a surface provided by the embedder. This could be an OpenGL, Metal, or Vulkan surface.
The embedder must handle swapping buffers, resizing, and other rendering details.

4. Event Handling
The embedder translates native platform events (like touch, keyboard input, etc.) into Flutter events and sends them to the engine:

Pointer Events: Converted into FlutterPointerEvent and sent via FlutterEngineSendPointerEvent.
Window Metrics: Translated into FlutterWindowMetricsEvent and sent to the engine.
Platform Messages: Received via the platform channels and handled within the embedder or passed to the Flutter engine.
5. Lifecycle Management
The embedder manages the lifecycle of the Flutter engine:

It starts the engine, manages its runtime, and shuts it down when no longer needed.
It must handle pausing, resuming, and other state transitions.
6. Task Runner
The ABI requires the embedder to implement a task runner:

The task runner is responsible for executing tasks scheduled by the engine on the appropriate thread (UI, IO, or GPU).
It’s implemented via callbacks that the embedder provides.
7. Platform Channels
The platform channels are critical for interacting with the underlying OS or platform APIs:

Messages sent from Dart are passed to the native side, where the embedder can handle them.
Responses from the native side can be sent back to Dart.
8. Engine and ABI Versioning
The Flutter Embedder ABI is versioned, and you must ensure that the engine and the embedder are compatible in terms of ABI versions.

9. Custom Embedders
A custom embedder allows Flutter to be run on platforms that are not natively supported (like custom desktop environments, game consoles, or IoT devices). You can tailor the interaction between Flutter and the platform to meet the specific requirements of your target environment.

10. Typical Use Case Flow
Initialization: The embedder initializes the Flutter engine with the necessary callbacks and resources.
Event Loop: The embedder runs an event loop, handling platform events and forwarding them to the Flutter engine.
Rendering: The engine renders frames, and the embedder handles displaying these frames.
Shutdown: When the application exits, the embedder shuts down the engine and cleans up resources.
Conclusion
The Flutter Embedder ABI provides a powerful and flexible way to integrate Flutter into almost any platform. By implementing the embedder API, you can control how Flutter interacts with the system’s rendering, event handling, and platform channels, enabling Flutter apps to run seamlessly on a wide range of devices.
