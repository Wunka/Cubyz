const std = @import("std");

const main = @import("../../../main.zig");
const vec = main.vec;
const Vec2f = vec.Vec2f;

const gui = @import("../../gui.zig");
const GuiComponent = gui.GuiComponent;
const ItemSlot = GuiComponent.ItemSlot;

const CISlot = @This();

slot: *ItemSlot,
pressed: bool = false,
pos: Vec2f,
size: Vec2f,

pub fn init(slot: *ItemSlot) *CISlot {
	const self = main.globalAllocator.create(CISlot);
	self.* = CISlot{
		.slot = slot,
		.pos = slot.pos,
		.size = slot.size,
	};
	return self;
}

pub fn deinit(self: *const CISlot) void {
	self.slot.deinit();
	main.globalAllocator.destroy(self);
}

pub fn toComponent(self: *CISlot) GuiComponent {
	return .{.cislot = self};
}

pub fn render(self: *CISlot, mousePosition: Vec2f) void {
	self.slot.pos = self.pos;
	self.slot.render(mousePosition);
}

pub fn mainButtonPressed(self: *CISlot, mousePosition: Vec2f) main.callbacks.Result {
	if (main.game.Player.isCreative()) {
		return self.slot.mainButtonPressed(mousePosition);
	}

	self.pressed = true;
	return .handled;
}

pub fn mainButtonReleased(self: *CISlot, mousePosition: Vec2f) void {
	if (main.game.Player.isCreative()) {
		self.slot.mainButtonReleased(mousePosition);
		return;
	}
	if (self.pressed) {
		self.pressed = false;
		if (GuiComponent.contains(self.pos, self.size, mousePosition)) {
			gui.windowlist.ci_window.openWithItem(self.slot.inventory.getItem(self.slot.itemSlot).baseItem);
		}
	}
}

pub fn updateHovered(self: *CISlot, pos: Vec2f) main.callbacks.Result {
	return self.slot.updateHovered(pos);
}
