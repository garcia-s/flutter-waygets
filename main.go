package main

import (
	"fmt"
	"github.com/neurlang/wayland/wl"
	"github.com/neurlang/wayland/wlclient"
	"log"
)

func (s SurfaceHaver) HandleRegistryGlobalRemove(ev wl.RegistryGlobalRemoveEvent) {}
func (s SurfaceHaver) HandleRegistryGlobal(ev wl.RegistryGlobalEvent) {
	if ev.Interface == "wl_compositor" {
		s.cptr = wlclient.RegistryBindCompositorInterface(s.reg, ev.Name, 3)
        wl.Surface
	}
	fmt.Printf("Hello, ev %v\n", ev)
}

type SurfaceHaver struct {
	wlclient.RegistryListener
	reg  *wl.Registry
	disp *wl.Display
	cptr *wl.Compositor
}

func NewSurfaceHaver() (*SurfaceHaver, error) {

	i := SurfaceHaver{}

	var err error
	i.disp, err = wlclient.DisplayConnect([]byte("wayland-1"))

	if err != nil {
		return nil, err
	}

	i.reg, err = i.disp.GetRegistry()

	if err != nil {
		return nil, err
	}

	wlclient.RegistryAddListener(i.reg, i)

	if wlclient.DisplayRoundtrip(i.disp) != nil {
		log.Fatalf("Failed the roundtrip")
	}

	return &i, nil

}

func main() { // Connect to the Wayland display

	haver, err := NewSurfaceHaver()
    surface = haver. 
	if err != nil {
		log.Fatalf("Error al intentar obener el compositor: %v", err)
	}
}
