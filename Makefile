PROTOCOLS_DIR := ./protocols
INCLUDE_DIR := ./include

PROTOCOLS := $(wildcard $(PROTOCOLS_DIR)/*.xml)

HEADERS := $(patsubst $(PROTOCOLS_DIR)/%.xml,$(INCLUDE_DIR)/%-client-protocol.h,$(PROTOCOLS))
SOURCES := $(patsubst $(PROTOCOLS_DIR)/%.xml,$(INCLUDE_DIR)/%-protocol.c,$(PROTOCOLS))

all: $(HEADERS) $(SOURCES)
$(INCLUDE_DIR)/%-client-protocol.h: $(PROTOCOLS_DIR)/%.xml
	wayland-scanner client-header $< $@

$(INCLUDE_DIR)/%-protocol.c: $(PROTOCOLS_DIR)/%.xml
	wayland-scanner private-code $< $@


variant := host_debug_unopt


run:
	zig build 
	./zig-out/bin/flutter_embedder ./ ./include/icudtl.dat

debug: 
	gdb run 

bundle: 
	flutter pub add flutter_gpu --sdk=flutter
	flutter build bundle
	run

clean:
	rm -f $(HEADERS) $(SOURCES)

