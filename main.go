package main

import (
	"fmt"
	"log"
	"github.com/neurlang/wayland/wl"
	"github.com/neurlang/wayland/wlclient"
)

func (s SurfaceHaver) HandleRegistryGlobalRemove(ev wl.RegistryGlobalRemoveEvent) {}
func (s SurfaceHaver) HandleRegistryGlobal(ev wl.RegistryGlobalEvent) {
	if ev.Interface == "wl_compositor" {
		wlclient.RegistryBindCompositorInterface(s.reg, ev.Name, 3)
	}
	fmt.Printf("Hello, ev %v\n", ev)
}

type SurfaceHaver struct {
	wlclient.RegistryListener
	reg  *wl.Registry
	disp *wl.Display
	cptr bool
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

	_, err := NewSurfaceHaver()

	if err != nil {
		log.Fatalf("Error al intentar obener el compositor: %v", err)
	}
}
