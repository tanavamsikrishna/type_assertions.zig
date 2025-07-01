const std = @import("std");
pub const interface = @import("interface.zig");

test {
    std.testing.refAllDeclsRecursive(@This());
}
