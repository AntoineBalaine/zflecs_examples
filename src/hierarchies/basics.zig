const std = @import("std");
const ecs = @import("zflecs");

const Position = struct {
    x: f64,
    y: f64,
};
const Local = struct {};
const World = struct {};
pub fn main() void {
    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.COMPONENT(world, Position);
    const positionId = ecs.id(Position);
    // Tags for local/ecs position
    ecs.TAG(world, Local);
    ecs.TAG(world, World);
    const World_id = ecs.id(World);
    const Local_id = ecs.id(Local);
    // Create a hierarchy. For an explanation see the entities/hierarchy example
    const sun = ecs.new_entity(world, "Sun");
    ecs.add_pair(world, sun, positionId, World_id);
    _ = ecs.set_pair(world, sun, positionId, Local_id, Position, Position{ .x = 1, .y = 1 });

    const mercury = ecs.new_entity(world, "Mercury");
    ecs.add_pair(world, mercury, ecs.ChildOf, sun);
    ecs.add_pair(world, mercury, positionId, World_id);
    _ = ecs.set_pair(world, mercury, positionId, Local_id, Position, Position{ .x = 1, .y = 1 });

    const venus = ecs.new_entity(world, "Venus");
    ecs.add_pair(world, venus, ecs.ChildOf, sun);
    ecs.add_pair(world, venus, positionId, World_id);
    _ = ecs.set_pair(world, venus, positionId, Local_id, Position, Position{ .x = 2, .y = 2 });

    const earth = ecs.new_entity(world, "Earth");
    ecs.add_pair(world, earth, ecs.ChildOf, sun);
    ecs.add_pair(world, earth, positionId, World_id);
    _ = ecs.set_pair(world, earth, positionId, Local_id, Position, Position{ .x = 3, .y = 3 });

    const moon = ecs.new_entity(world, "Moon");
    ecs.add_pair(world, moon, ecs.ChildOf, earth);
    ecs.add_pair(world, moon, positionId, World_id);
    _ = ecs.set_pair(world, moon, positionId, Local_id, Position, Position{ .x = 0.1, .y = 0.1 });

    // Create a hierarchical query to compute the global position from the
    // local position and the parent position.
    var desc = ecs.query_desc_t{};
    // Read from entity's Local position
    desc.terms[0] = .{ .id = ecs.pair(ecs.id(Position), Local_id), .inout = .In };
    // Write to entity's World position
    desc.terms[1] = .{ .id = ecs.pair(ecs.id(Position), World_id), .inout = .Out };

    // Read from parent's World position
    desc.terms[2] = .{
        .id = ecs.pair(ecs.id(Position), World_id),
        .inout = .In,
        // Get from the parent in breadth-first order (cascade)
        .src = ecs.term_ref_t{ .id = ecs.Cascade },
        // Make parent term optional so we also match the root (sun)
        .oper = .Optional,
    };
    const q = ecs.query_init(world, &desc) catch unreachable;
    defer ecs.query_fini(q);

    // Do the transform
    var it = ecs.query_iter(world, q);
    while (ecs.query_next(&it)) {
        const p = ecs.field(&it, Position, 0);
        const p_out = ecs.field(&it, Position, 1);
        const p_parent = ecs.field(&it, Position, 2);

        if (p_out) |p_out_| {
            // Inner loop, iterates entities in archetype
            for (0..it.count()) |i| {
                p_out_[i].x = p.?[i].x;
                p_out_[i].y = p.?[i].y;
                if (p_parent) |parent| {
                    p_out_[i].x += parent[0].x;
                    p_out_[i].y += parent[0].y;
                }
            }
        }
    }

    // Print ecs positions
    // const child = ecs.new_w_pair(world, ecs.ChildOf, parent);
    // it = ecs.each_pair_t(world, positionId, World);
    it = ecs.each_id(world, ecs.pair(positionId, World_id));
    while (ecs.each_next(&it)) {
        const p = ecs.field(&it, Position, 0);
        for (0..it.count()) |i| {
            std.debug.print("{s}: [ {d}, {d} ]\n", .{ ecs.get_name(world, it.entities()[i]).?, p.?[i].x, p.?[i].y });
        }
    }
}
