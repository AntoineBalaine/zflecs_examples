const std = @import("std");
const ecs = @import("zflecs");
const entities = @import("entities.zig");

pub fn main() !void {
    entities.basics();
    entities.hierarchy();
    entities.iterate_components();
}
