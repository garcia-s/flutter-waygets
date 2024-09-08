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




run:
	zig build -- -fsanitize=thread

	./zig-out/bin/flutter_embedder ./ ./include/icudtl.dat --trace-skia --verbose

bundle: 

	flutter pub add flutter_gpu --sdk=flutter
	flutter --verbose build bundle --debug \
			--local-engine-src-path ../src \
			--local-engine=host_debug_unopt \
			--local-engine-host=host_debug_unopt  

clean:
	rm -f $(HEADERS) $(SOURCES)

