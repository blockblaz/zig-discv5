const std = @import("std");
const zbench = @import("zbench");
const enr = @import("enr");

const ENR = enr.ENR;
const EncodedENR = enr.EncodedENR;

fn GetBenchmark(comptime T: type) type {
    return struct {
        e: *T,
        key: []const u8,

        const Self = @This();
        pub fn init(e: *T, key: []const u8) Self {
            return Self{ .e = e, .key = key };
        }

        pub fn run(self: Self, _: std.mem.Allocator) void {
            _ = self.e.get(self.key);
        }
    };
}

test "bench" {
    const enr_txt = "enr:-IS4QHCYrYZbAKWCBRlAy5zzaDZXJBGkcnh4MHcBFZntXNFrdvJjX04jRzjzCBOonrkTfj499SZuOh8R33Ls8RRcy5wBgmlkgnY0gmlwhH8AAAGJc2VjcDI1NmsxoQPKY0yuDUmstAHYpMa2_oxVtw0RW_QAdpzBQA8yWM0xOIN1ZHCCdl8";
    var decoded_enr: ENR = undefined;
    try ENR.decodeTxtInto(&decoded_enr, enr_txt);
    var encoded_enr = try EncodedENR.decodeTxtInto(enr_txt);

    const stdout = std.io.getStdErr().writer();
    var bench = zbench.Benchmark.init(std.testing.allocator, .{});
    defer bench.deinit();

    try bench.addParam("ENR get(secp256k1)", &GetBenchmark(ENR).init(&decoded_enr, "secp256k1"), .{});
    try bench.addParam("ENR get(udp)", &GetBenchmark(ENR).init(&decoded_enr, "udp"), .{});
    try bench.addParam("EncodedENR get(secp256)", &GetBenchmark(EncodedENR).init(&encoded_enr, "secp256k1"), .{});
    try bench.addParam("EncodedENR get(udp)", &GetBenchmark(EncodedENR).init(&encoded_enr, "udp"), .{});

    try bench.run(stdout);
}
