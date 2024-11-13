const std = @import("std");
const ecs = @import("zflecs");

const Position = struct { x: f32, y: f32 };
const Walking = struct {};

pub fn main() void {
    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.COMPONENT(world, Position);
    ecs.TAG(world, Walking);
    // Create an entity with name Bob
    const bob = ecs.new_entity(world, "Bob");

    // The set operation finds or creates a component, and sets it.
    _ = ecs.set(world, bob, Position, Position{ .x = 10, .y = 20 });
    // The add operation adds a component without setting a value. This is
    // useful for tags, or when adding a component with its default value.
    ecs.add(world, bob, Walking);

    // Get the value for the Position component
    const ptr = ecs.get(world, bob, Position) orelse return;
    std.debug.print("{d}, {d}\n", .{ ptr.x, ptr.y });

    // Overwrite the value of the Position component
    _ = ecs.set(world, bob, Position, Position{ .x = 20, .y = 30 });

    // Create another named entity
    const alice = ecs.new_entity(world, "Alice");
    _ = ecs.set(world, alice, Position, Position{ .x = 10, .y = 20 });
    ecs.add(world, alice, Walking);

    // Print all the components the entity has. This will output:
    //    Position, Walking, (Identifier,Name)
    const type_str = ecs.type_str(world, ecs.get_type(world, alice)) orelse return;
    std.debug.print("[{s}]\n", .{type_str});
    ecs.os.free(type_str);

    // Remove tag
    ecs.remove(world, alice, Walking);

    // Iterate all entities with Position

    var it = ecs.each_id(world, ecs.id(Position));
    while (ecs.each_next(&it)) {
        // NOTE: I can’t grok why the index field needs to be 0
        const p = ecs.field(&it, Position, 0) orelse return;
        for (it.entities(), 0..) |entity, i| {
            std.debug.print("{s}: {d}, {d}\n", .{ ecs.get_name(world, entity).?, p[i].x, p[i].y });
        }
    }
}
