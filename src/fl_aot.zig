const std = @import("std");
const c = @import("c_imports.zig").c;

const SymbolUnavailable = error.SymbolUnavailable;

pub fn get_aot_data(path: []u8, args: *c.FlutterProjectArgs) !void {
    var lib = try std.DynLib.open(path);

    const vm_snapshot_data_sym = lib.lookup([*c]u8, "_kDartVmSnapshotData").?;
    const vm_isolate_snapshot_instructions_sym = lib.lookup([*c]u8, "_kDartIsolateSnapshotInstructions").?;
    const vm_isolate_snapshot_data_sym = lib.lookup([*c]u8, "_kDartIsolateSnapshotData").?;
    const vm_snapshot_instructions_sym = lib.lookup([*c]u8, "_kDartVmSnapshotInstructions").?;

    args.vm_snapshot_data = vm_snapshot_data_sym.?;
    args.isolate_snapshot_instructions = vm_isolate_snapshot_instructions_sym.?;
    args.isolate_snapshot_data = vm_isolate_snapshot_data_sym.?;
    args.vm_snapshot_instructions = vm_snapshot_instructions_sym.?;
}
