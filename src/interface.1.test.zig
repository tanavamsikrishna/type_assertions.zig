const interface_mod = @import("interface.zig");
const interface = interface_mod.interface;
const iThis = interface_mod.iThis;

test {
    const MyInterface = interface(.{ .some = fn (iThis, u32) void });
    const MyStruct = struct {
        pub fn some(self: @This(), a: u32) u32 {
            _ = a;
            _ = self;
            return 123;
        }
    };
    MyInterface.implby(MyStruct);
    const obj = MyStruct{};
    _ = obj.some(23);
}
