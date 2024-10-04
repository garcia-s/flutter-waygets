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
    queue: std.PriorityQueue(Task, void, cmp) = undefined,

    pub fn init(
        self: *FLTaskRunner,
        _: std.mem.Allocator,
        thread: usize,
        engine: *c.FlutterEngine,
    ) !void {
        self.alloc = std.heap.page_allocator;
        self.queue = std.PriorityQueue(Task, void, cmp).init(self.alloc, undefined);
        self.thread = thread;
        self.engine = engine;
    }

    pub fn post_task(self: *FLTaskRunner, task: Task) !void {
        try self.queue.add(task);
    }

    pub fn run_next_task(self: *FLTaskRunner) void {
        const frame_delay = std.time.ns_per_s / 60;
        var task = self.queue.peek() orelse {
            std.time.sleep(frame_delay);
            return;
        };

        const delta: u64 = task.time -| c.FlutterEngineGetCurrentTime();
        if (delta > 0) {
            std.time.sleep(delta);
        }

        task = self.queue.remove();
        self.run_flutter_task(task.task);
    }

    fn run_flutter_task(self: *FLTaskRunner, task: c.FlutterTask) void {
        const result = c.FlutterEngineRunTask(self.engine.*, &task);
        if (result != c.kSuccess) {
            std.debug.print("Error running the task {?}\n ", .{task});
        }
    }

    fn cmp(_: void, a: Task, b: Task) std.math.Order {
        return std.math.order(a.time, b.time);
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
