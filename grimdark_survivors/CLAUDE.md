# Grimdark Survivors - Development Context

## Project Overview
A dark fantasy action roguelike with humorous undertones, inspired by Vampire Survivors, Megabonk, and similar survivors-like games. Features keyboard-only controls, dozens of unlockable characters, and massive build variety through weapons, items, and abilities.

## Tech Stack
- Engine: Godot 4.3+
- Language: GDScript (NOT Godot 3 syntax - always use Godot 4 patterns)
- Architecture: Component-based with signals for loose coupling
- Target: Windows PC (low-end hardware compatible)

## Code Conventions
- PascalCase for class names and node names
- snake_case for functions, variables, signals
- SCREAMING_SNAKE_CASE for constants
- Keep scripts under 200 lines - split into components/autoloads if larger
- No hardcoded values - use Resource files or constants
- All game events go through EventBus autoload
- All damage calculations go through DamageSystem
- Use @export for inspector-configurable values
- Use typed variables (var health: int = 100)
- Prefer composition over inheritance

## Input System (KEYBOARD ONLY - NO MOUSE)
- WASD: Movement (8-directional)
- Space: Dodge roll
- E: Interact/Confirm
- Q: Cancel/Back
- Tab: Pause menu
- 1-6: Quick select (level-up choices, menu navigation)
- Arrow Keys: Alternative movement / menu navigation
- Enter: Confirm (alternative to E)
- Escape: Pause (alternative to Tab)

## Game Architecture

### Autoloads (load order matters)
1. EventBus - Central event/signal hub
2. GameManager - Game state, run management
3. SaveManager - Persistent data, unlocks
4. AudioManager - Sound effects and music
5. InputManager - Input handling and remapping

### Component System
Entities use composition via these components:
- HealthComponent: HP, damage, death
- HitboxComponent: Deals damage to hurtboxes
- HurtboxComponent: Receives damage from hitboxes
- MovementComponent: Velocity, acceleration, knockback
- StatsComponent: All modifiable stats (speed, damage, etc.)

### Signal Flow
1. Hitbox enters Hurtbox → Hurtbox emits "hit_received"
2. Hurtbox notifies HealthComponent → HealthComponent emits "damage_taken" / "died"
3. EventBus broadcasts death → GameManager updates score, spawners notified
4. XP gem spawns → Player collects → EventBus "xp_gained" → Check level up

## Current Development Status
- [x] Project structure
- [x] Core autoloads
- [ ] Player controller
- [ ] Basic enemy
- [ ] Combat system
- [ ] XP and leveling
- [ ] Weapon system
- [ ] UI systems
- [ ] Meta progression

## Performance Targets
- Maintain 60 FPS with 500+ enemies on screen
- Use object pooling for projectiles, enemies, XP gems
- Minimize per-frame allocations
- Use Areas for collision, not raycasts for mass entities

## Art Style Notes
- Low-poly / retro pixel art aesthetic
- Dark fantasy with vibrant accent colors
- 32x32 or 64x64 base sprite size
- Limited color palette per entity type
- Exaggerated, readable silhouettes

## Humor Guidelines
- Item/weapon names should be punny or absurd
- Character descriptions self-aware and silly
- Death messages should be darkly comedic
- Achievement names reference gaming culture
- Serious fantasy aesthetics, not-serious text
