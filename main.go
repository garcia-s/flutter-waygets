package main

import (
	"github.com/neurlang/wayland/os"
	"github.com/neurlang/wayland/wl"
	"github.com/neurlang/wayland/wlclient"
	"log"
)

func (s SurfaceHaver) HandleRegistryGlobalRemove(ev wl.RegistryGlobalRemoveEvent) {}
func (s SurfaceHaver) HandleRegistryGlobal(ev wl.RegistryGlobalEvent) {

	switch ev.Interface {
	case "wl_compositor":
		s.cptr = wlclient.RegistryBindCompositorInterface(s.reg, ev.Name, 3)
		s.cptr.CreateSurface()
		var err error
		s.surf, err = s.cptr.CreateSurface()
		size := 300 * 4 * 300

		if err != nil {
			log.Fatalf("Failed to get the surface %v", err)
		}

		fd, err := os.CreateAnonymousFile(int64(3000))
		_, err = os.Mmap(int(fd.Fd()), 0,
			size, os.ProtRead|os.ProtWrite, os.MapShared)

		if err != nil {
			log.Fatalf("Failed to get the surface %v", err)
		}

		if err != nil {
			log.Fatalf("failed to create an shm file %v", err)
		}

	case "wl_shm":
		s.shm = wlclient.RegistryBindShmInterface(s.reg, ev.Name, 1)
		// wlclient.ShmAddListener(s.shm, )

	default:

	}
}

type SurfaceHaver struct {
	wlclient.RegistryListener
	reg  *wl.Registry
	disp *wl.Display
	cptr *wl.Compositor
	surf *wl.Surface
	shm  *wl.Shm
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
