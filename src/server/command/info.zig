const std = @import("std");

const main = @import("main");
const User = main.server.User;

pub const description = "Get or set the server info.";
pub const usage = "/info\n/info set <Text>";

pub fn execute(args: []const u8, source: *User) void {
	var split = std.mem.splitScalar(u8, args, ' ');
	if (split.next()) |arg| blk: {
		if (arg.len == 0) break :blk;
		if (!std.ascii.eqlIgnoreCase(arg, "set")) {
			source.sendMessage("Expected no or set + <Tex> arguments, found \"{s}\"", .{arg});
			return;
		}
		if (split.peek() == null) {
			source.sendMessage("Got \"info set\" but no info to set", .{});
			return;
		}
		if (!source.hasPermission("/command/set/info")) {
			source.sendMessage("#ff0000No permission to use Command \"/info set\"", .{});
			return;
		}
		main.globalAllocator.free(main.server.world.?.info);
		main.server.world.?.info = main.globalAllocator.dupe(u8, split.rest());
		return;
	}
	source.sendMessage("#ffff00{s}", .{main.server.world.?.info});
}
