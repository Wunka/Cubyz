// TODO: Remove after https://codeberg.org/ziglang/zig/issues/31912 was merged

// zig fmt: off

//! Condition variables are used with a Mutex to efficiently wait for an arbitrary condition to occur.
//! It does this by atomically unlocking the mutex, blocking the thread until notified, and finally re-locking the mutex.
//! Condition can be statically initialized and is at most `@sizeOf(u64)` large.
//!
//! Example:
//! ```
//! var m = Mutex{};
//! var c = Condition{};
//! var predicate = false;
//!
//! fn consumer() void {
//!     m.lock();
//!     defer m.unlock();
//!
//!     while (!predicate) {
//!         c.wait(&m);
//!     }
//! }
//!
//! fn producer() void {
//!     {
//!         m.lock();
//!         defer m.unlock();
//!         predicate = true;
//!     }
//!     c.signal();
//! }
//!
//! const thread = try std.Thread.spawn(.{}, producer, .{});
//! consumer();
//! thread.join();
//! ```
//!
//! Note that condition variables can only reliably unblock threads that are sequenced before them using the same Mutex.
//! This means that the following is allowed to deadlock:
//! ```
//! thread-1: mutex.lock()
//! thread-1: condition.wait(&mutex)
//!
//! thread-2: // mutex.lock() (without this, the following signal may not see the waiting thread-1)
//! thread-2: // mutex.unlock() (this is optional for correctness once locked above, as signal can be called while holding the mutex)
//! thread-2: condition.signal()
//! ```

const std = @import("std");
const main = @import("main");
const builtin = @import("builtin");
const Mutex = main.utils.Mutex;

const os = std.os;
const assert = std.debug.assert;
const testing = std.testing;
const Futex = main.utils.Futex;

const Condition = @This();

super: std.Io.Condition = .init,

/// Atomically releases the Mutex, blocks the caller thread, then re-acquires the Mutex on return.
/// "Atomically" here refers to accesses done on the Condition after acquiring the Mutex.
///
/// The Mutex must be locked by the caller's thread when this function is called.
/// A Mutex can have multiple Conditions waiting with it concurrently, but not the opposite.
/// It is undefined behavior for multiple threads to wait ith different mutexes using the same Condition concurrently.
/// Once threads have finished waiting with one Mutex, the Condition can be used to wait with another Mutex.
///
/// A blocking call to wait() is unblocked from one of the following conditions:
/// - a spurious ("at random") wake up occurs
/// - a future call to `signal()` or `broadcast()` which has acquired the Mutex and is sequenced after this `wait()`.
///
/// Given wait() can be interrupted spuriously, the blocking condition should be checked continuously
/// irrespective of any notifications from `signal()` or `broadcast()`.
pub fn wait(self: *Condition, mutex: *Mutex) void {
    self.super.wait(main.io, &mutex.super) catch {};
}

/// Atomically releases the Mutex, blocks the caller thread, then re-acquires the Mutex on return.
/// "Atomically" here refers to accesses done on the Condition after acquiring the Mutex.
///
/// The Mutex must be locked by the caller's thread when this function is called.
/// A Mutex can have multiple Conditions waiting with it concurrently, but not the opposite.
/// It is undefined behavior for multiple threads to wait ith different mutexes using the same Condition concurrently.
/// Once threads have finished waiting with one Mutex, the Condition can be used to wait with another Mutex.
///
/// A blocking call to `timedWait()` is unblocked from one of the following conditions:
/// - a spurious ("at random") wake occurs
/// - the caller was blocked for around `timeout_ns` nanoseconds, in which `error.Timeout` is returned.
/// - a future call to `signal()` or `broadcast()` which has acquired the Mutex and is sequenced after this `timedWait()`.
///
/// Given `timedWait()` can be interrupted spuriously, the blocking condition should be checked continuously
/// irrespective of any notifications from `signal()` or `broadcast()`.
pub fn timedWait(self: *Condition, mutex: *Mutex, timeout: std.Io.Duration) error{Timeout}!void {
	self.super.waitTimeout(main.io, &mutex.super, .{.duration = .{.raw = timeout, .clock = .awake}}) catch |err| {
            if(err == error.Timeout) return error.Timeout;     
        };
}

/// Unblocks at least one thread blocked in a call to `wait()` or `timedWait()` with a given Mutex.
/// The blocked thread must be sequenced before this call with respect to acquiring the same Mutex in order to be observable for unblocking.
/// `signal()` can be called with or without the relevant Mutex being acquired and have no "effect" if there's no observable blocked threads.
pub fn signal(self: *Condition) void {
	self.super.signal(main.io);
}

/// Unblocks all threads currently blocked in a call to `wait()` or `timedWait()` with a given Mutex.
/// The blocked threads must be sequenced before this call with respect to acquiring the same Mutex in order to be observable for unblocking.
/// `broadcast()` can be called with or without the relevant Mutex being acquired and have no "effect" if there's no observable blocked threads.
pub fn broadcast(self: *Condition) void {
	self.super.broadcast(main.io);
}
