const c = @import("c_imports.zig").c;
const std = @import("std");

const Task = struct {
    time: u64,
    task: c.FlutterTask,
};

pub fn create_fl_runner(runner: *FLTaskRunner) c.FlutterTaskRunnerDescription {
    return c.FlutterTaskRunnerDescription{
        .struct_size = @sizeOf(c.FlutterTaskRunnerDescription),
        .runs_task_on_current_thread_callback = @ptrCast(&runs_task_on_current_thread),
        .post_task_callback = @ptrCast(&post_task_callback),
        .user_data = @ptrCast(runner),
        .identifier = 1,
    };
}

pub const FLTaskRunner = struct {
    thread: usize = undefined,
    alloc: std.mem.Allocator = undefined,
    engine: *c.FlutterEngine = undefined,
    queue: std.ArrayList(Task) = undefined,

    pub fn init(
        self: *FLTaskRunner,
        _: std.mem.Allocator,
        thread: usize,
        engine: *c.FlutterEngine,
    ) !void {
        self.alloc = std.heap.page_allocator;
        self.queue = std.ArrayList(Task).init(self.alloc);
        self.thread = thread;
        self.engine = engine;
    }

    pub fn post_task(self: *FLTaskRunner, task: Task) !void {
        try self.queue.append(task);
    }

    pub fn run_next_task(self: *FLTaskRunner) void {
        var task = self.queue.getLastOrNull() orelse {
            std.time.sleep(16e7);
            return;
        };

        if (c.FlutterEngineGetCurrentTime() < task.time) {
            std.time.sleep(16e7);
            return;
        }

        task = self.queue.pop();
        self.run_flutter_task(task.task);
    }

    fn run_flutter_task(self: *FLTaskRunner, task: c.FlutterTask) void {
        const result = c.FlutterEngineRunTask(self.engine.*, &task);
        if (result != c.kSuccess) {
            std.debug.print("Error running the task {?}\n ", .{task});
        }
    }
};

pub fn post_task_callback(task: c.FlutterTask, time: u64, data: ?*anyopaque) callconv(.C) void {
    const runner: *FLTaskRunner = @ptrCast(@alignCast(data));
    runner.post_task(Task{ .time = time, .task = task }) catch |err| {
        std.debug.print("Error posting task: {}\n", .{err});
    };
}

pub fn runs_task_on_current_thread(data: ?*anyopaque) callconv(.C) bool {
    const runner: *FLTaskRunner = @ptrCast(@alignCast(data));
    return std.Thread.getCurrentId() == runner.thread;
}
