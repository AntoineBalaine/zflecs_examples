const std = @import("std");
const ecs = @import("zflecs");

const Position = struct { x: f32, y: f32 };
const Velocity = struct { x: f32, y: f32 };
const Human = struct {};
const Eats = struct {};
const Apples = struct {};

fn iterate_components(world: *ecs.world_t, e: ecs.entity_t) void {
    // First get the entity's type, which is a vector of (component) ids.
    const type_t = ecs.get_type(world, e) orelse return;

    // 1. The easiest way to print the components is to use ecs.type_str
    const type_str = ecs.type_str(world, type_t) orelse return;
    std.debug.print("ecs_type_str: {s}\n\n", .{type_str});
    ecs.os.free(type_str);

    // 2. To print individual ids, iterate the type array with ecs.id_str
    const type_ids = type_t.array;
    const count = type_t.count;

    for (0..@intCast(count)) |i| {
        const id = type_ids[i];
        const id_str = ecs.id_str(world, id) orelse return;
        std.debug.print("{d}: {s}\n", .{ i, id_str });
        ecs.os.free(id_str);
    }

    std.debug.print("\n", .{});

    // 3. We can also inspect and print the ids in our own way. This is a
    // bit more complicated as we need to handle the edge cases of what can be
    // encoded in an id, but provides the most flexibility.
    for (0..@intCast(count)) |i| {
        const id = type_ids[i];

        std.debug.print("{d}: ", .{i});

        if (ecs.id_is_pair(id)) { // See relationships
            const rel = ecs.pair_first(id);
            const tgt = ecs.pair_second(id);
            std.debug.print("rel: {s}, tgt: {s}", .{ ecs.get_name(world, rel) orelse "", ecs.get_name(world, tgt) orelse "" });
        } else {
            const comp = id & ecs.COMPONENT_MASK;
            std.debug.print("entity: {s}", .{ecs.get_name(world, comp) orelse ""});
        }

        std.debug.print("\n", .{});
    }

    std.debug.print("\n\n", .{});
}

pub fn main() void {
    const world = ecs.init();
    defer _ = ecs.fini(world);

    // Ordinary components
    ecs.COMPONENT(world, Position);
    ecs.COMPONENT(world, Velocity);

    // A tag
    ecs.TAG(world, Human);

    // Two tags used to create a pair
    ecs.TAG(world, Eats);
    ecs.TAG(world, Apples);

    // Create an entity which has all of the above
    const Bob = ecs.new_entity(world, "Bob");

    _ = ecs.set(world, Bob, Position, Position{ .x = 10, .y = 20 });
    _ = ecs.set(world, Bob, Velocity, Velocity{ .x = 1, .y = 1 });
    ecs.add(world, Bob, Human);
    ecs.add_pair(world, Bob, ecs.id(Eats), ecs.id(Apples));

    // Iterate & components of Bob
    std.debug.print("Bob's components:\n", .{});
    iterate_components(world, Bob);

    // We can use the same function to iterate the components of a component
    std.debug.print("Position's components:\n", .{});
    iterate_components(world, ecs.id(Position));
}

// FIXME: output’s incorrect

// ecs_type_str: main.Position, main.Velocity, main.Human, (Identifier,Name), (main.Eats,main.Apples)
//
// 0: main.Position
// 1: main.Velocity
// 2: main.Human
// 3: (Identifier,Name)
// 4: (main.Eats,main.Apples)
//
// 0: entity: Position
// 1: entity: Velocity
// 2: entity: Human
// 3: rel: Identifier, tgt: Name
// 4: rel: Eats, tgt: Apples
//
//
// Position's components:
// ecs_type_str: Component, (Identifier,Name), (Identifier,Symbol), (ChildOf,main)
//
// 0: Component
// 1: (Identifier,Name)
// 2: (Identifier,Symbol)
// 3: (ChildOf,main)
//
// 0: entity: Component
// 1: rel: Identifier, tgt: Name
// 2: rel: Identifier, tgt: Symbol
// 3: rel: ChildOf, tgt: main
