const std = @import("std");
const Allocator = std.mem.Allocator;
const Address = std.net.Address;
const WhoAreYouPacket = @import("./packet.zig").WhoAreYouPacket;
const enr = @import("./enr.zig");
const session = @import("./session.zig");
const xev = @import("xev");
const UDP = xev.UDP;

const Discv5 = struct {
    loop: xev.Loop,
    udp: xev.UDP,
    config: Config,

    read_c: xev.Completion = .{},
    read_buf: xev.ReadBuffer,
    read_state: xev.UDP.State = .{ .op = .{ .recv = .{ .buf = undefined, .msghdr = undefined, .iov = undefined } } },

    const Config = struct {
        bind_addr: Address,
    };

    const Self = @This();

    pub fn init(config: Config) !Discv5 {
        const loop = try xev.Loop.init(.{});
        const udp = try UDP.init(config.bind_addr);
        var buf: [1000]u8 = undefined;
        return Discv5{ .loop = loop, .udp = udp, .config = config, .read_buf = .{ .slice = &buf } };
    }

    pub fn run(self: *Self) !void {
        try self.udp.bind(self.config.bind_addr);
        self.udp.read(&self.loop, &self.read_c, &self.read_state, self.read_buf, Self, self, readCallback);
        try self.loop.run(.until_done);
    }

    fn readCallback(
        self_: ?*Self,
        _: *xev.Loop,
        _: *xev.Completion,
        _: *UDP.State,
        addr: Address,
        _: UDP,
        b: xev.ReadBuffer,
        r: xev.ReadError!usize,
    ) xev.CallbackAction {
        //
        _ = self_;
        _ = addr;
        const size = r catch unreachable;
        std.debug.print("{any}\n", .{b.slice[0..size]});
        return .rearm;
    }
};

test "dv5" {
    var d = try Discv5.init(.{ .bind_addr = try Address.parseIp("127.0.0.1", 5006) });
    try d.run();
}

const NodeAddress = struct {
    socket_addr: Address,
    node_id: enr.NodeId,
};

const Request = struct {};

const Challenge = struct {
    data: *session.ChallengeData,
    enr: enr.EncodedENR,
};

const SessionManager = struct {
    active_request_nonce_mapping: std.StringHashMapUnmanaged(NodeAddress),
    active_requests: std.AutoHashMapUnmanaged(NodeAddress, Request),
    active_challenges: std.AutoHashMapUnmanaged(NodeAddress, Challenge),
    pending_requests: std.fifo.LinearFifo(Request, .{.Slice}),

    const Options = struct {
        active_requests_size: u32,
        sessions_size: u32,
        request_timeout: u32,
        request_retries: u32,
        session_timeout: u32,
        session_establishment_timeout: u32,
    };

    const Self = @This();

    // pub fn init(allocator: Allocator, options: Options) !Self {}

    // pub fn deinit(self: *Self, allocator: Allocator) void {}

    // pub fn inboundWhoAreYou(self: Self, src: Address, packet: WhoAreYouPacket) !void {}
};
