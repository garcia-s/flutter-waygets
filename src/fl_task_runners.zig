const c = @import("c_imports.zig").c;
const std = @import("std");

const Task = struct {
    time: u64,
    task: *c.FlutterTask,
};
pub fn create_fl_runner(runner: *FLTaskRunner) c.FlutterTaskRunnerDescription {
    return c.FlutterTaskRunnerDescription{
        .struct_size = @sizeOf(c.FlutterTaskRunnerDescription),
        .runs_task_on_current_thread_callback = @ptrCast(&runs_task_on_current_thread),
        .post_task_callback = @ptrCast(&post_task_callback),
        .user_data = @ptrCast(runner),
    };
}

pub const FLTaskRunner = struct {
    thread: usize = undefined,
    alloc: std.mem.Allocator = undefined,
    engine: *c.FlutterEngine = undefined,
    queue: std.ArrayList(*const c.FlutterTask) = undefined,

    pub fn init(
        self: *FLTaskRunner,
        _: std.mem.Allocator,
        thread: usize,
        engine: *c.FlutterEngine,
    ) !void {
        self.alloc = std.heap.page_allocator;
        self.queue = std.ArrayList(*const c.FlutterTask).init(self.alloc);
        self.thread = thread;
        self.engine = engine;
    }

    pub fn post_task(self: *FLTaskRunner, task: *const c.FlutterTask) !void {
        try self.queue.append(task);
    }

    pub fn run_next_task(self: *FLTaskRunner) void {
        const task = self.queue.popOrNull();
        if (task != null) self.run_flutter_task(task.?);
    }

    fn run_flutter_task(self: *FLTaskRunner, task: *const c.FlutterTask) void {
        const result = c.FlutterEngineRunTask(self.engine.*, task);
        if (result != c.kSuccess) {
            std.debug.print("Error running the task {?}\n ", .{task});
        }
    }
};

pub fn post_task_callback(task: c.FlutterTask, _: u64, data: ?*anyopaque) callconv(.C) void {
    const runner: *FLTaskRunner = @ptrCast(@alignCast(data));
    runner.post_task(&task) catch |err| {
        std.debug.print("Error posting task: {}\n", .{err});
    };
}

pub fn runs_task_on_current_thread(data: ?*anyopaque) callconv(.C) bool {
    const runner: *FLTaskRunner = @ptrCast(@alignCast(data));
    return std.Thread.getCurrentId() == runner.thread;
}
