const std = @import("std");
const SymbolUnavailable = error.SymbolUnavailable;

pub fn get_aot_data(
    path: []u8,
    vm_snapshot_data: *[*c]const u8,
    vm_snapshot_instructions: *[*c]const u8,
    vm_isolate_snapshot_data: *[*c]const u8,
    vm_isolate_snapshot_instructions: *[*c]const u8,
) !void {
    var lib = try std.DynLib.open(path);

    const vm_snapshot_data_sym = lib.lookup([*c]u8, "_kDartVmSnapshotData").?;
    const vm_isolate_snapshot_instructions_sym = lib.lookup([*c]u8, "_kDartIsolateSnapshotInstructions").?;
    const vm_isolate_snapshot_data_sym = lib.lookup([*c]u8, "_kDartIsolateSnapshotData").?;
    const vm_snapshot_instructions_sym = lib.lookup([*c]u8, "_kDartVmSnapshotInstructions").?;

    vm_snapshot_data.* = vm_snapshot_data_sym.?;
    vm_isolate_snapshot_instructions.* = vm_isolate_snapshot_instructions_sym.?;
    vm_isolate_snapshot_data.* = vm_isolate_snapshot_data_sym.?;
    vm_snapshot_instructions.* = vm_snapshot_instructions_sym.?;
}
