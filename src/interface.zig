const std = @import("std");
const Type = std.builtin.Type;

pub const iThis = enum {};

fn check_if_params_match(param_in_interface: ?type, param_in_implementer: ?type, implementer: type) bool {
    if (param_in_interface == null) {
        return true;
    } else if (param_in_interface != null and param_in_implementer == null) {
        return false;
    }
    const int_typeinfo = @typeInfo(param_in_interface.?);
    const imp_typeinfo = @typeInfo(param_in_implementer.?);
    return switch (int_typeinfo) {
        .pointer => if (imp_typeinfo != .pointer)
            false
        else
            check_if_params_match(int_typeinfo.pointer.child, imp_typeinfo.pointer.child, implementer),
        else => std.meta.eql(if (param_in_interface == iThis) implementer else param_in_interface.?, param_in_implementer.?),
    };
}

pub fn interface(interface_def: anytype) type {
    const ArgsType = @TypeOf(interface_def);
    const args_type_info = @typeInfo(ArgsType);
    if (args_type_info != .@"struct") {
        @compileError("expected struct argument, found " ++ @typeName(ArgsType));
    }
    const interface_fields = args_type_info.@"struct".fields;
    return struct {
        pub fn implby(comptime implementer: type) void {
            comptime {
                for (interface_fields) |interface_field| {
                    const interface_field_name = interface_field.name;

                    // check if fn with the name found
                    const implementor_decl = if (@hasDecl(implementer, interface_field_name))
                        @field(implementer, interface_field_name)
                    else {
                        const error_msg = std.fmt.comptimePrint("{s} does not implement `{s}` (or not marked as pub)", .{ @typeName(implementer), interface_field_name });
                        @compileError(error_msg);
                    };

                    const implementer_decl_fn_info = @typeInfo(@TypeOf(implementor_decl)).@"fn";
                    const interface_field_fn_info = @typeInfo(@field(interface_def, interface_field_name)).@"fn";

                    // check for fn input params match
                    if (implementer_decl_fn_info.params.len != interface_field_fn_info.params.len) {
                        const error_msg = std.fmt.comptimePrint("Different number of fields for {s} {any} {any}", .{ interface_field_name, implementer_decl_fn_info, interface_field_fn_info });
                        @compileError(error_msg);
                    }
                    for (implementer_decl_fn_info.params, interface_field_fn_info.params, 0..) |imp_fn_param, int_fn_param, index| {
                        if (check_if_params_match(int_fn_param.type, imp_fn_param.type, implementer)) {
                            continue;
                        }
                        const error_msg = std.fmt.comptimePrint("The type of {d}-nd parameters of fn `{s}` mismatch. Expected `{any}`. Found `{any}`.", .{ index + 1, interface_field_name, int_fn_param.type, imp_fn_param.type });
                        @compileError(error_msg);
                    }

                    // check if fn return param match
                    if (implementer_decl_fn_info.return_type != interface_field_fn_info.return_type) {

                        // check if fn return param match
                        const error_msg = std.fmt.comptimePrint("The return params for `{s}` do not match. Expected `{any}`. Found `{any}`.", .{ interface_field_name, interface_field_fn_info.return_type, implementer_decl_fn_info.return_type });
                        @compileError(error_msg);
                    }
                }
            }
        }
    };
}

test {
    const MyInterface = interface(.{ .some = fn (iThis, u32) u32 });
    const MyStruct = struct {
        fn some(self: @This(), a: u32) u32 {
            _ = a;
            _ = self;
            return 123;
        }
    };
    MyInterface.implby(MyStruct);
    const obj = MyStruct{};
    _ = obj.some(23);
}
