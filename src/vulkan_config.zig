const c = @cImport({
    @cInclude("flutter_embedder.h");
});

pub const FlutterVulkanRendererConfig = extern struct {
    /// The size of this struct. Must be sizeof(FlutterVulkanRendererConfig).
    struct_size: comptime_int,

    /// The Vulkan API version. This should match the value set in
    /// VkApplicationInfo::apiVersion when the VkInstance was created.
    version: u32,
    /// VkInstance handle. Must not be destroyed before `FlutterEngineShutdown` is
    /// called.
    instance: c.FlutterVulkanInstanceHandle,

    handle: c.VkPhysicalDevice,
    /// VkPhysicalDevice handle
    physical_device: c.FlutterVulkanPhysicalDeviceHandle,
    /// VkDevice handle. Must not be destroyed before `FlutterEngineShutdown` is
    /// called.
    device: c.FlutterVulkanDeviceHandle,
    /// The queue family index of the VkQueue supplied in the next field.
    queue_family_index: u32,
    /// VkQueue handle.
    /// The queue should not be used without protection from a mutex to make sure
    /// it is not used simultaneously with other threads. That mutex should match
    /// the one injected via the |get_instance_proc_address_callback|.
    /// There is a proposal to remove the need for the mutex at
    /// https://github.com/flutter/flutter/issues/134573.
    queue: c.FlutterVulkanQueueHandle,
    /// The number of instance extensions available for enumerating in the next
    /// field.
    enabled_instance_extension_count: u32,
    /// Array of enabled instance extension names. This should match the names
    /// passed to `VkInstanceCreateInfo.ppEnabledExtensionNames` when the instance
    /// was created, but any subset of enabled instance extensions may be
    /// specified.
    /// This field is optional: c., `nullptr` may be specified.
    /// This memory is only accessed during the call to FlutterEngineInitialize.
    enabled_instance_extensions: [*c]const []u8,
    /// The number of device extensions available for enumerating in the next
    /// field.
    enabled_device_extension_count: comptime_int,
    /// Array of enabled logical device extension names. This should match the
    /// names passed to `VkDeviceCreateInfo.ppEnabledExtensionNames` when the
    /// logical device was created, but any subset of enabled logical device
    /// extensions may be specified.
    /// This field is optional: c., `nullptr` may be specified.
    /// This memory is only accessed during the call to FlutterEngineInitialize.
    /// For example: VK_KHR_GET_MEMORY_REQUIREMENTS_2_EXTENSION_NAME
    enabled_device_extensions: [*c]const []u8,
    /// The callback invoked when resolving Vulkan function pointers.
    /// At a bare minimum this should be used to swap out any calls that operate
    /// on vkQueue's for threadsafe variants that obtain locks for their duration.
    /// The functions to swap out are "vkQueueSubmit" and "vkQueueWaitIdle".  An
    /// example of how to do that can be found in the test
    /// "EmbedderTest.CanSwapOutVulkanCalls" unit-test in
    /// //shell/platform/embedder/tests/embedder_vk_unittests.cc.
    get_instance_proc_address_callback: c.FlutterVulkanInstanceProcAddressCallback,
    /// The callback invoked when the engine requests a VkImage from the embedder
    /// for rendering the next frame.
    /// Not used if a FlutterCompositor is supplied in FlutterProjectArgs.
    get_next_image_callback: c.FlutterVulkanImageCallback,
    /// The callback invoked when a VkImage has been written to and is ready for
    /// use by the embedder. Prior to calling this callback, the engine performs
    /// a host sync, and so the VkImage can be used in a pipeline by the embedder
    /// without any additional synchronization.
    /// Not used if a FlutterCompositor is supplied in FlutterProjectArgs.
    present_image_callback: c.FlutterVulkanPresentCallback,
};
