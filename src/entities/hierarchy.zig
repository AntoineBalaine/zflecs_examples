const std = @import("std");
const ecs = @import("zflecs");

const Position = struct { x: f32, y: f32 };

// Forward declare component so we can use it from functions other than main
// ECS_COMPONENT_DECLARE(Position);

fn iterate_tree(world: *ecs.world_t, e: ecs.entity_t, p_parent: Position) void {
    // Print hierarchical name of entity & the entity type
    const path_str = ecs.get_path(world, e, 0) orelse return;
    const type_str = ecs.type_str(world, ecs.get_type(world, e)) orelse return;
    defer ecs.os.free(type_str);
    defer ecs.os.free(path_str);

    std.debug.print("{s} [{s}]\n", .{ path_str, type_str });

    // Get entity position
    const ptr = ecs.get(world, e, Position) orelse return;

    // Calculate actual position
    const p_actual = Position{ .x = ptr.x + p_parent.x, .y = ptr.y + p_parent.y };
    std.debug.print("{}, {}\n\n", .{ p_actual.x, p_actual.y });

    // Iterate children recursively
    var it = ecs.children(world, e);
    while (ecs.children_next(&it)) {
        for (it.entities()) |child| {
            iterate_tree(world, child, p_actual);
        }
    }
}

const Star = struct {};
const Planet = struct {};
const Moon = struct {};

pub fn main() void {
    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.COMPONENT(world, Position);
    ecs.TAG(world, Star);
    ecs.TAG(world, Planet);
    ecs.TAG(world, Moon);

    // Create a simple hierarchy.
    // Hierarchies use ECS relationships and the builtin flecs::ChildOf relationship to
    // create entities as children of other entities.
    //
    const sun = ecs.new_entity(world, "Sun");
    ecs.add(world, sun, Star);
    _ = ecs.set(world, sun, Position, Position{ .x = 1, .y = 1 });

    const mercury = ecs.new_entity(world, "Mercury");
    ecs.add_pair(world, mercury, ecs.ChildOf, sun);

    // NOTE: example code has this marked as
    // `ecs.add(world, mercury, ecs.lookup("Planet"));`
    // Which unfortunately can’t fly because zig can’t call external functions at comptime.
    ecs.add(world, mercury, Planet);
    _ = ecs.set(world, mercury, Position, Position{ .x = 1, .y = 1 });

    const venus = ecs.new_entity(world, "Venus");
    ecs.add_pair(world, venus, ecs.ChildOf, sun);
    ecs.add(world, venus, Planet);
    _ = ecs.set(world, venus, Position, Position{ .x = 2, .y = 2 });

    const earth = ecs.new_entity(world, "Earth");
    ecs.add_pair(world, earth, ecs.ChildOf, sun);
    ecs.add(world, earth, Planet);
    _ = ecs.set(world, earth, Position, Position{ .x = 3, .y = 3 });

    const moon = ecs.new_entity(world, "Moon");
    ecs.add_pair(world, moon, ecs.ChildOf, earth);
    ecs.add(world, moon, Moon);
    _ = ecs.set(world, moon, Position, Position{ .x = 0.1, .y = 0.1 });

    // Is the Moon a child of Earth?
    std.debug.print("Child of Earth? {}\n\n", .{ecs.has_pair(world, moon, ecs.ChildOf, earth)});

    // // Lookup moon by name
    const e = ecs.lookup(world, "Sun.Earth.Moon");
    const path = ecs.get_path_w_sep(world, e, 0, ".", null) orelse return;
    std.debug.print("Moon found: {s}\n\n", .{path});

    ecs.os.free(path);

    // Do a depth-first walk of the tree
    iterate_tree(world, sun, Position{ .x = 0, .y = 0 });
}

// FIXME: this is not the same output as c example

// Child of Earth? true
//
// Moon found: #0
//
// #0 [main.Position, main.Star, (Identifier,Name)]
// 1e0, 1e0
//
// #0 [main.Position, main.Planet, (Identifier,Name), (ChildOf,Sun)]
// 2e0, 2e0
//
// #0 [main.Position, main.Planet, (Identifier,Name), (ChildOf,Sun)]
// 3e0, 3e0
//
// #0 [main.Position, main.Planet, (Identifier,Name), (ChildOf,Sun)]
// 4e0, 4e0
//
// #0 [main.Position, main.Moon, (Identifier,Name), (ChildOf,Sun.Earth)]
// 4.1e0, 4.1e0
