// TODO: Remove after https://codeberg.org/ziglang/zig/issues/31912 was merged

// zig fmt: off

//! A semaphore is an unsigned integer that blocks the kernel thread if
//! the number would become negative.
//! This API supports static initialization and does not require deinitialization.
//!
//! Example:
//! ```
//! var s = Semaphore{};
//!
//! fn consumer() void {
//!     s.wait();
//! }
//!
//! fn producer() void {
//!     s.post();
//! }
//!
//! const thread = try std.Thread.spawn(.{}, producer, .{});
//! consumer();
//! thread.join();
//! ```

const std = @import("std");
const main = @import("main");

const Semaphore = @This();
super: std.Io.Semaphore = .{},

pub fn wait(sem: *Semaphore) void {
    sem.super.wait(main.io) catch {};
}

pub fn timedWait(sem: *Semaphore, timeout: std.Io.Duration) error{Timeout}!void {
    return sem.super.waitTimeout(main.io, .{.duration = .{.raw = timeout, .clock = .awake}}) catch |err| {
            if(err == error.Timeout) return error.Timeout; 
    };
}

pub fn post(sem: *Semaphore) void {
    sem.super.post(main.io);
}
