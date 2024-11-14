const std = @import("std");
const ecs = @import("zflecs");
const entities = @import("entities.zig");
const hierarchies = @import("hierarchies.zig");

pub fn main() !void {
    entities.basics();
    entities.hierarchy();
    entities.iterate_components();
    hierarchies.basics();
}
