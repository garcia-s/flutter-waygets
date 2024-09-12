PROTOCOLS_DIR := ./protocols
INCLUDE_DIR := ./include
ZIG_OUT := ./include
ZIG_CACHE := ./include
DART_TOOLS := ./include
FLUTTER_BUILD := ./protocols
GEN_PATH := $(FLUTTER_PATH)/cache/artifacts/engine/linux-x64-release/gen_snapshot

PROTOCOLS := $(wildcard $(PROTOCOLS_DIR)/*.xml)

HEADERS := $(patsubst $(PROTOCOLS_DIR)/%.xml,$(INCLUDE_DIR)/%-client-protocol.h,$(PROTOCOLS))
SOURCES := $(patsubst $(PROTOCOLS_DIR)/%.xml,$(INCLUDE_DIR)/%-protocol.c,$(PROTOCOLS))

protocols: $(HEADERS) $(SOURCES)
$(INCLUDE_DIR)/%-client-protocol.h: $(PROTOCOLS_DIR)/%.xml
	wayland-scanner client-header $< $@

$(INCLUDE_DIR)/%-protocol.c: $(PROTOCOLS_DIR)/%.xml
	wayland-scanner private-code $< $@


embedder:
	zig build

run:
	./zig-out/bin/flutter_embedder ./widgets/status_bar/ ./include/icudtl.dat


core: 
	$(GEN_PATH) \
		--snapshot_kind=core 											\
		--vm_snapshot_data=./build/vm_snapshot_data						\
		--isolate_snapshot_data=build/isolate_snapshot_data           	\
		--verbose														\
		./widgets/status_bar/build/kernel_snapshot.dill

clean:
	rm -f $(HEADERS) $(SOURCES) $(FLUTTER_BUILD) $(DART_TOOLS) $(ZIG_BUILD) $(ZIG_CACHE)

