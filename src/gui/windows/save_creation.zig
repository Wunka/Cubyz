const std = @import("std");

const build_options = @import("build_options");

const main = @import("main");
const ConnectionManager = main.network.ConnectionManager;
const settings = main.settings;
const Vec2f = main.vec.Vec2f;
const NeverFailingAllocator = main.heap.NeverFailingAllocator;
const Texture = main.graphics.Texture;
const ZonElement = main.ZonElement;

const gui = @import("../gui.zig");
const GuiComponent = gui.GuiComponent;
const GuiWindow = gui.GuiWindow;
const Button = @import("../components/Button.zig");
const HorizontalList = @import("../components/HorizontalList.zig");
const Label = @import("../components/Label.zig");
const TextInput = @import("../components/TextInput.zig");
const CheckBox = @import("../components/CheckBox.zig");
const VerticalList = @import("../components/VerticalList.zig");
const TabList = @import("../components/TabList.zig");

pub var window = GuiWindow{
	.contentSize = Vec2f{128, 256},
};

const padding: f32 = 8;

var nameInput: *TextInput = undefined;
var seedInput: *TextInput = undefined;

var gamemodeInput: *Button = undefined;

var worldSettings = main.server.world_zig.Settings.defaults;

const ZonMapEntry = std.StringHashMapUnmanaged(ZonElement).Entry;
var worldPresets: []ZonMapEntry = &.{};
var selectedPreset: usize = undefined;
var defaultPreset: usize = 0;
var presetButton: *Button = undefined;

var needsUpdate: bool = false;

var deleteIcon: Texture = undefined;
var fileExplorerIcon: Texture = undefined;

var tabs: *TabList = undefined;
var tabName: *Label = undefined;

fn getGenerationTab() *VerticalList {
	const submenu = VerticalList.init(.{0, 0}, 384, 8);
	const maxWidth = 192;
	{ // world preset
		const row = HorizontalList.init();
		row.add(Label.init(.{0, 0}, maxWidth - 128, "Preset:", .left));
		presetButton = Button.initText(.{0, 0}, 128, worldPresets[selectedPreset].key_ptr.*, .init(worldPresetCallback));
		row.add(presetButton);
		row.finish(.{0, 0}, .center);
		submenu.add(row);
	}

	{ // seed
		const row = HorizontalList.init();
		row.add(Label.init(.{0, 0}, 48, "Seed:", .left));
		seedInput = TextInput.init(.{0, 0}, maxWidth - 48, 22, "", .{.onNewline = .init(createWorld)});
		row.add(seedInput);
		row.finish(.{0, 0}, .center);
		submenu.add(row);
	}
	submenu.finish(.center);
	return submenu;
}
fn getGameruleTab() *VerticalList {
	const submenu = VerticalList.init(.{0, 0}, 384, 8);
	const maxWidth = 192;
	{
		const row = HorizontalList.init();
		row.add(Label.init(.{0, 0}, maxWidth - 96, "Game Mode:", .left));
		gamemodeInput = Button.initText(.{0, 0}, 96, @tagName(worldSettings.defaultGamemode), .init(gamemodeCallback));
		row.add(gamemodeInput);
		row.finish(.{0, 0}, .center);
		submenu.add(row);
	}

	submenu.add(CheckBox.init(.{0, 0}, maxWidth, "Allow Cheats", worldSettings.allowCheats, &allowCheatsCallback));
	submenu.finish(.center);
	return submenu;
}

fn prevPage() void {
	tabs.previousTab();
	tabName.updateText(tabs.getTitle());
	needsUpdate = true;
}

fn nextPage() void {
	tabs.nextTab();
	tabName.updateText(tabs.getTitle());
	needsUpdate = true;
}

fn chooseSeed(seedStr: []const u8) u64 {
	if (seedStr.len == 0) {
		return main.random.nextInt(u64, &main.seed);
	} else {
		return std.fmt.parseInt(u64, seedStr, 0) catch {
			return std.hash.Wyhash.hash(0, seedStr);
		};
	}
}

fn gamemodeCallback() void {
	worldSettings.defaultGamemode = std.meta.intToEnum(main.game.Gamemode, @intFromEnum(worldSettings.defaultGamemode) + 1) catch @enumFromInt(0);
	gamemodeInput.child.label.updateText(@tagName(worldSettings.defaultGamemode));
}

fn worldPresetCallback() void {
	selectedPreset += 1;
	if (selectedPreset == worldPresets.len) selectedPreset = 0;
	presetButton.child.label.updateText(worldPresets[selectedPreset].key_ptr.*);
}

fn allowCheatsCallback(allow: bool) void {
	worldSettings.allowCheats = allow;
}

fn testingModeCallback(enabled: bool) void {
	worldSettings.testingMode = enabled;
}

fn createWorld() void {
	const worldName = nameInput.currentString.items;
	worldSettings.seed = chooseSeed(seedInput.currentString.items);

	main.server.world_zig.tryCreateWorld(worldName, worldSettings, worldPresets[selectedPreset].value_ptr.*) catch |err| {
		std.log.err("Error while creating new world: {s}", .{@errorName(err)});
	};
	gui.closeWindowFromRef(&window);
	gui.windowlist.save_selection.needsUpdate = true;
	gui.openWindow("save_selection");
}

pub fn onOpen() void {
	const list = VerticalList.init(.{padding, 16 + padding}, 500, 8);

	if (worldPresets.len == 0) {
		var presetMap = main.assets.worldPresets();
		var entryList: main.ListUnmanaged(ZonMapEntry) = .initCapacity(main.globalArena, presetMap.count());
		var iterator = presetMap.iterator();
		while (iterator.next()) |entry| {
			entryList.appendAssumeCapacity(entry);
		}

		std.sort.insertion(ZonMapEntry, entryList.items, {}, struct {
			fn lessThanFn(_: void, lhs: ZonMapEntry, rhs: ZonMapEntry) bool {
				return std.ascii.lessThanIgnoreCase(lhs.key_ptr.*, rhs.key_ptr.*);
			}
		}.lessThanFn);
		worldPresets = entryList.items;
		for (worldPresets, 0..) |entry, i| {
			if (std.mem.eql(u8, entry.key_ptr.*, "cubyz:default")) {
				defaultPreset = i;
			}
		}
	}
	if (!needsUpdate) selectedPreset = defaultPreset;
	tabs = TabList.init(.{0, 8});
	tabs.add("Generation (1/2)", getGenerationTab());
	tabs.add("Game Rules (2/2)", getGameruleTab());
	tabs.finish();

	{ // name field
		const label = Label.init(.{0, 0}, 96, "World Name:", .center);
		var num: usize = 1;
		while (true) {
			const path = std.fmt.allocPrint(main.stackAllocator.allocator, "saves/Save{}", .{num}) catch unreachable;
			defer main.stackAllocator.free(path);
			if (!main.files.cubyzDir().hasDir(path)) break;
			num += 1;
		}
		const name = std.fmt.allocPrint(main.stackAllocator.allocator, "Save{}", .{num}) catch unreachable;
		defer main.stackAllocator.free(name);
		nameInput = TextInput.init(.{0, 0}, 256 - 96, 22, name, .{.onNewline = .init(createWorld)});
		const nameRow = HorizontalList.init();
		nameRow.add(label);
		nameRow.add(nameInput);
		nameRow.finish(.{0, 0}, .center);
		list.add(nameRow);
	}

	{ // page title and switch buttons
		const leftArrow = Button.initText(.{0, 0}, 24, "<", .init(prevPage));
		tabName = Label.init(.{0, 0}, 224 - 48, tabs.getTitle(), .center);
		const rightArrow = Button.initText(.{0, 0}, 24, ">", .init(nextPage));
		const header = HorizontalList.init();
		header.add(leftArrow);
		header.add(tabName);
		header.add(rightArrow);
		header.finish(.{0, 0}, .center);
		list.add(header);
	}

	list.add(tabs);

	if (!build_options.isTaggedRelease) {
		list.add(CheckBox.init(.{0, 0}, 192, "Testing mode (for developers)", worldSettings.testingMode, &testingModeCallback));
	}

	list.add(Button.initText(.{0, 0}, 128, "Create World", .init(createWorld)));

	list.finish(.center);
	window.rootComponent = list.toComponent();
	window.contentSize = window.rootComponent.?.pos() + window.rootComponent.?.size() + @as(Vec2f, @splat(padding));
	gui.updateWindowPositions();
}

pub fn onClose() void {
	if (window.rootComponent) |*comp| {
		comp.deinit();
	}
}
