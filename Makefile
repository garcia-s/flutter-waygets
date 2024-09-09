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



#flutter --verbose build bundle --debug \
#	--local-engine-src-path ../src \
#	--local-engine=host_debug_unopt \
#	--local-engine-host=host_debug_unopt  

embedder:
	zig build -- -fsanitize=thread

run:
	./zig-out/bin/flutter_embedder ./ ./include/icudtl.dat

dev: bundle embedder run

clean:
	rm -f $(HEADERS) $(SOURCES) $(FLUTTER_BUILD) $(DART_TOOLS) $(ZIG_BUILD) $(ZIG_CACHE)

