PROTOCOLS_DIR := ./protocols
INCLUDE_DIR := ./include
ZIG_OUT := ./include
ZIG_CACHE := ./include
DART_TOOLS := ./include
FLUTTER_BUILD := ./protocols


PROTOCOLS := $(wildcard $(PROTOCOLS_DIR)/*.xml)

HEADERS := $(patsubst $(PROTOCOLS_DIR)/%.xml,$(INCLUDE_DIR)/%-client-protocol.h,$(PROTOCOLS))
SOURCES := $(patsubst $(PROTOCOLS_DIR)/%.xml,$(INCLUDE_DIR)/%-protocol.c,$(PROTOCOLS))

protocols: $(HEADERS) $(SOURCES)
$(INCLUDE_DIR)/%-client-protocol.h: $(PROTOCOLS_DIR)/%.xml
	wayland-scanner client-header $< $@

$(INCLUDE_DIR)/%-protocol.c: $(PROTOCOLS_DIR)/%.xml
	wayland-scanner private-code $< $@


bundle: 
	flutter --verbose build bundle


kernel:
	/home/symmetry/dev/flutter/bin/cache/dart-sdk/bin/dartaotruntime \
	  	$(HOME)/dev/flutter/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot     \
		--sdk-root $(HOME)/dev/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk   \
		--target=flutter                             \
		--tfa                                       \
		-Ddart.vm.product=true                       \
		--packages ./.dart_tool/package_config.json  \
		--output-dill build/kernel_snapshot.dill     \
		package:flutter_waygets/main.dart

#flutter --verbose build bundle --debug \
#	--local-engine-src-path ../src \
#	--local-engine=host_debug_unopt \
#	--local-engine-host=host_debug_unopt  


aot: 
	$(HOME)/dev/flutter/bin/cache/artifacts/engine/linux-x64-release/gen_snapshot\
		--causal_async_stacks                                         \
		--packages=.packages                                          \
		--deterministic                                               \
		--snapshot_kind=app-aot-blobs                                 \
		--vm_snapshot_data=build/vm_snapshot_data                     \
		--isolate_snapshot_data=build/isolate_snapshot_data           \
		--vm_snapshot_instructions=build/vm_snapshot_instr            \
		--isolate_snapshot_instructions=build/isolate_snapshot_instr  \
		--no-sim-use-hardfp                                           \
		--no-use-integer-division                                     \
		build/kernel_snapshot.dill


embedder:
	zig build -- -fsanitize=thread

run:
	./zig-out/bin/flutter_embedder ./ ./include/icudtl.dat

dev: bundle embedder run

clean:
	rm -f $(HEADERS) $(SOURCES) $(FLUTTER_BUILD) $(DART_TOOLS) $(ZIG_BUILD) $(ZIG_CACHE)

