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

embedder:
	zig build

run:
	./zig-out/bin/flutter_embedder ./widgets/status_bar/ ./include/icudtl.dat


#This is the command to compile a flutter project
aot:
	flutter assemble -v -dBuildMode="release" \
		-dTargetPlatform="linux-x64" \
		--output="./build/release" release_bundle_linux-x64_assets 

clean:
	rm -f $(HEADERS) $(SOURCES) $(FLUTTER_BUILD) $(DART_TOOLS) $(ZIG_BUILD) $(ZIG_CACHE)

