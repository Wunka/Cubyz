const std = @import("std");

// MARK: functionPtrCast()
fn CastFunctionSelfToConstAnyopaqueType(Fn: type) type {
	const typeInfo = @typeInfo(Fn);
	var paramTypes: [typeInfo.@"fn".param_types.len]type = undefined;
	var paramAttributes: [typeInfo.@"fn".param_types.len]std.builtin.Type.Fn.ParamAttributes = undefined;
	for (typeInfo.@"fn".param_types, typeInfo.@"fn".param_attrs, 0..) |@"type", attrs, i| {
		paramTypes[i] = @"type".?;
		paramAttributes[i] = attrs;
	}
	const isMutablePointer = @typeInfo(paramTypes[0]) == .pointer and !@typeInfo(paramTypes[0]).pointer.attrs.@"const";
	if (@sizeOf(paramTypes[0]) != @sizeOf(*const anyopaque) or @alignOf(paramTypes[0]) != @alignOf(*const anyopaque) or isMutablePointer) {
		@compileError(std.fmt.comptimePrint("Cannot convert {} to *const anyopaque", .{paramTypes[0]}));
	}
	paramTypes[0] = *const anyopaque;
	return @Fn(&paramTypes, &paramAttributes, typeInfo.@"fn".return_type.?, .{.@"callconv" = typeInfo.@"fn".attrs.@"callconv", .varargs = typeInfo.@"fn".attrs.varargs});
}
/// Turns the first parameter into a *const anyopaque
pub fn castFunctionSelfToConstAnyopaque(function: anytype) *const CastFunctionSelfToConstAnyopaqueType(@TypeOf(function)) {
	return @ptrCast(&function);
}

// MARK: functionPtrCast()
fn CastFunctionSelfToAnyopaqueType(Fn: type) type {
	const typeInfo = @typeInfo(Fn);
	var paramTypes: [typeInfo.@"fn".param_types.len]type = undefined;
	var paramAttributes: [typeInfo.@"fn".param_types.len]std.builtin.Type.Fn.ParamAttributes = undefined;
	for (typeInfo.@"fn".param_types, typeInfo.@"fn".param_attrs, 0..) |@"type", attrs, i| {
		paramTypes[i] = @"type".?;
		paramAttributes[i] = attrs;
	}
	if (@sizeOf(paramTypes[0]) != @sizeOf(*anyopaque) or @alignOf(paramTypes[0]) != @alignOf(*anyopaque)) {
		@compileError(std.fmt.comptimePrint("Cannot convert {} to *anyopaque", .{paramTypes[0]}));
	}
	paramTypes[0] = *anyopaque;
	return @Fn(&paramTypes, &paramAttributes, typeInfo.@"fn".return_type.?, typeInfo.@"fn".attrs);
}
/// Turns the first parameter into a *anyopaque
pub fn castFunctionSelfToAnyopaque(function: anytype) *const CastFunctionSelfToAnyopaqueType(@TypeOf(function)) {
	return @ptrCast(&function);
}

fn CastFunctionReturnToAnyopaqueType(Fn: type) type {
	const typeInfo = @typeInfo(Fn);
	var paramTypes: [typeInfo.@"fn".param_types.len]type = undefined;
	var paramAttributes: [typeInfo.@"fn".param_types.len]std.builtin.Type.Fn.ParamAttributes = undefined;
	for (typeInfo.@"fn".param_types, typeInfo.@"fn".param_attrs, 0..) |@"type", attrs, i| {
		paramTypes[i] = @"type".?;
		paramAttributes[i] = attrs;
	}
	if (@sizeOf(typeInfo.@"fn".return_type.?) != @sizeOf(*anyopaque) or @alignOf(typeInfo.@"fn".return_type.?) != @alignOf(*anyopaque) or @typeInfo(typeInfo.@"fn".return_type.?) == .optional) {
		@compileError(std.fmt.comptimePrint("Cannot convert {} to *anyopaque", .{typeInfo.@"fn".return_type.?}));
	}
	const ReturnType = *anyopaque;
	return @Fn(&paramTypes, &paramAttributes, ReturnType, typeInfo.@"fn".attrs);
}

fn CastFunctionReturnToOptionalAnyopaqueType(Fn: type) type {
	const typeInfo = @typeInfo(Fn);
	var paramTypes: [typeInfo.@"fn".param_types.len]type = undefined;
	var paramAttributes: [typeInfo.@"fn".param_types.len]std.builtin.Type.Fn.ParamAttributes = undefined;
	for (typeInfo.@"fn".param_types, typeInfo.@"fn".param_attrs, 0..) |@"type", attrs, i| {
		paramTypes[i] = @"type".?;
		paramAttributes[i] = attrs;
	}
	if (@sizeOf(typeInfo.@"fn".return_type.?) != @sizeOf(?*anyopaque) or @alignOf(typeInfo.@"fn".return_type.?) != @alignOf(?*anyopaque) or @typeInfo(typeInfo.@"fn".return_type.?) != .optional) {
		@compileError(std.fmt.comptimePrint("Cannot convert {} to ?*anyopaque", .{typeInfo.@"fn".return_type.?}));
	}
	const ReturnType = ?*anyopaque;
	return @Fn(&paramTypes, &paramAttributes, ReturnType, typeInfo.@"fn".attrs);
}
/// Turns the return parameter into a *anyopaque
pub fn castFunctionReturnToAnyopaque(function: anytype) *const CastFunctionReturnToAnyopaqueType(@TypeOf(function)) {
	return @ptrCast(&function);
}
pub fn castFunctionReturnToOptionalAnyopaque(function: anytype) *const CastFunctionReturnToOptionalAnyopaqueType(@TypeOf(function)) {
	return @ptrCast(&function);
}

pub fn concatComptime(comptime separator: []const u8, comptime array: anytype) []const u8 {
	comptime var str: []const u8 = "";
	comptime for (array, 0..) |fieldName, index| {
		str = str ++ fieldName;
		if (index < array.len - 1) str = str ++ separator;
	};
	return str;
}
