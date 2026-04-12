const std = @import("std");

const main = @import("main");
const User = main.server.User;

const command = @import("_command.zig");

pub const description = "list players";
pub const usage = "/list targets";

pub fn execute(args: []const u8, source: *User) void {
	var split = std.mem.splitScalar(u8, args, ' ');
	const targets = command.Targets.init(&split, main.globalAllocator, source) catch return;
	defer targets.deinit(main.globalAllocator);

	for (targets.users) |user| {
		source.sendMessage("#ffff00 {f}", .{user});
	}
}
