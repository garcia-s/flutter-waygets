const std = @import("std");
const c = @import("../c_imports.zig").c;

const TaskRunner = struct {
    allocator: *std.mem.Allocator = std.heap.page_allocator,
    task_queue: std.PriorityQueue(
        *c.FlutterTask,
        TaskRunner,
    ) = undefined,
    thread: std.Thread = undefined,

    pub fn init(self: *TaskRunner, allocator: *std.mem.Allocator) void {
        self.allocator = allocator;
        self.task_queue = std.PriorityQueue(*c.FlutterTask, TaskRunner, i64).init(allocator);
    }

    pub fn deinit(self: *TaskRunner) void {
        self.task_queue.deinit();
    }

    pub fn post_task(self: *TaskRunner, task: *c.FlutterTask, target_time_nanos: u64) void {
        const current_time = std.time.nanoTimestamp();
        const delay: i64 = @intCast(target_time_nanos - current_time);
        self.task_queue.put(task, delay);
    }

    pub fn run(self: *TaskRunner) void {
        while (true) {
            const current_time = std.time.nanoTimestamp();
            while (self.task_queue.len > 0) {
                const entry = self.task_queue.peek();
                if (entry.priority <= current_time) {
                    _ = self.task_queue.pop();
                    entry.item.function(entry.item, entry.item.identifier);
                } else {
                    std.time.sleep(entry.priority - current_time);
                }
            }
            std.time.sleep(10_000_000);
        }
    }
};

fn post_flutter_task(task: *c.FlutterTask, target_time_nanos: u64, user_data: ?*anyopaque) void {
    const runner = @field(user_data, "*TaskRunner");
    runner.post_task(task, target_time_nanos);
}

fn runs_task_on_current_thread(user_data: ?*anyopaque) callconv(.C) bool {
    const runner = @field(user_data, "*TaskRunner");
    return runner.thread.id == std.Thread.current().id;
}

pub fn create_task_runner_description() c.FlutterTaskRunnerDescription {
    var task_runner = TaskRunner.init();

    return c.FlutterTaskRunnerDescription{
        .user_data = &task_runner, // Store the task runner in user_data
        .runs_task_on_current_thread_callback = &runs_task_on_current_thread,
        .post_task_callback = &post_flutter_task,
    };
}
