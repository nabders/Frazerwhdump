# GRIMDARK SURVIVORS - Game Design Document

## High Concept
A dark fantasy action roguelike where players survive waves of undead horrors using auto-attacking weapons, collecting experience to level up and choose increasingly powerful abilities. Features keyboard-only controls, dozens of unlockable characters with unique playstyles, and thousands of possible build combinations. The game takes its visuals seriously but its writing not at all.

## Core Gameplay Loop
1. **Select Character** → Each has unique starting weapon + passive bonus
2. **Survive Waves** → Enemies spawn in increasing numbers/difficulty over 20 minutes
3. **Collect XP Gems** → Dropped by defeated enemies
4. **Level Up** → Choose 1 of 3-4 random upgrades (weapons, passives, abilities)
5. **Build Synergies** → Weapons evolve when paired with specific items
6. **Defeat Boss** → Appears at set intervals, drops treasure chests
7. **Death or Victory** → Earn gold and unlock progress based on performance
8. **Meta Progression** → Spend gold on permanent upgrades, unlock new characters

## Controls (Keyboard Only)
| Action | Primary | Alternative |
|--------|---------|-------------|
| Move | WASD | Arrow Keys |
| Dodge Roll | Space | - |
| Interact/Confirm | E | Enter |
| Cancel/Back | Q | Backspace |
| Pause | Tab | Escape |
| Select Option 1-6 | 1-6 keys | - |
| Navigate Menu | WASD | Arrow Keys |

## Characters (20+ Planned)

### Starting Characters (Unlocked)
1. **Sir Reginald the Adequate** - Knight
   - Starting Weapon: Rusty Sword (melee sweep)
   - Passive: +10% max HP
   - Flavor: "He's not the chosen one. He's not even the backup. But he showed up."

2. **Mirela the Slightly Gifted** - Mage
   - Starting Weapon: Fizzling Wand (magic projectiles)
   - Passive: +10% XP gain
   - Flavor: "Graduated middle of her class. From a correspondence course."

3. **Bork the Hungry** - Barbarian
   - Starting Weapon: Bone Club (heavy melee)
   - Passive: +15% damage when below 50% HP
   - Flavor: "He came for the violence. He stayed for the snacks."

### Unlockable Characters (Examples)
4. **Father Grimsby** - Plague Doctor (Kill 1000 enemies)
   - Starting Weapon: Incense Swinger (area denial)
   - Passive: Poison immunity, enemies near you take DOT

5. **Patches the Questionable** - Rogue (Find 50 treasure chests)
   - Starting Weapon: Throwing Knives (rapid projectiles)
   - Passive: +25% pickup radius

6. **Dame Margret** - Paladin (Defeat first boss)
   - Starting Weapon: Blessed Hammer (holy damage AoE)
   - Passive: Periodically heal nearby allies (if co-op) or self

7. **The Accountant** - Necromancer (Accumulate 10,000 gold total)
   - Starting Weapon: Spreadsheet of Doom (summons skeletal minions)
   - Passive: Enemies drop +10% gold

8. **Gwendolyn the Unfortunate** - Witch (Die 50 times)
   - Starting Weapon: Cauldron Toss (arcing splash damage)
   - Passive: +1 revival per run

9. **Lord Rattington III** - Giant Rat (Kill 500 rats specifically)
   - Starting Weapon: Gnawing Horde (summons rat swarm)
   - Passive: Tiny hitbox, +20% move speed

10. **Chef Gusteau's Ghost** - Specter Cook (Collect 100 food items)
    - Starting Weapon: Boiling Ladle (melee with burn)
    - Passive: Food items heal 50% more

### Secret Characters
- **The Developer** - Complete all achievements
- **Clippy** - Find the hidden MS Office dungeon

## Weapons System

### Weapon Categories
1. **Melee** - Close range, usually sweeping attacks
2. **Projectile** - Fires toward enemies or in patterns
3. **Orbital** - Circles around the player
4. **Area** - Damages zones on the ground
5. **Summon** - Creates entities that fight for you
6. **Passive Weapons** - Trigger automatically on conditions

### Base Weapons (25+)

**Melee Weapons:**
- Rusty Sword - Basic frontal sweep
- Bone Club - Slow heavy slam
- Dagger Dance - Rapid multi-stab combo
- Executioner's Blade - Massive damage, massive cooldown
- Flail of Questionable Safety - Spins around player unpredictably

**Projectile Weapons:**
- Fizzling Wand - Magic bolts toward nearest enemy
- Throwing Knives - Rapid stream of daggers
- Crossbow of Inaccuracy - High damage, questionable aim
- Bottle Chucker - Arcing poison bottles
- The Finger - Points at enemy, they take damage (it's rude)

**Orbital Weapons:**
- Orbiting Skulls - Bones circle the player
- Ring of Fire - Flame ring damages on contact
- Guardian Tomes - Books that shield and bonk
- The Entourage - Ghostly admirers that hurt enemies

**Area Weapons:**
- Hellfire Patch - Random ground fire
- Consecrated Ground - Holy damage zone at feet
- Spike Trap Enthusiast - Drops traps behind you
- Gravity Well - Pulls enemies to center, damages

**Summon Weapons:**
- Skeletal Posse - Summons skeletons that chase enemies
- Attack Chickens - Angry poultry assault
- Haunted Furniture - Possessed chairs attack nearby foes
- Tax Collectors - They always find their target

### Weapon Evolution System
When a weapon reaches max level (8) AND player has the paired passive item, defeating a boss drops an evolution chest.

| Base Weapon | + Passive Item | = Evolved Weapon |
|-------------|----------------|------------------|
| Rusty Sword | Whetstone | Excalibur-ish |
| Fizzling Wand | Empty Tome | Staff of Infinite Papercuts |
| Orbiting Skulls | Candle | Screaming Flaming Skulls |
| Throwing Knives | Leather Gloves | Blade Tornado |
| Hellfire Patch | Matchbook | Armageddon Lite |
| Skeletal Posse | Necro License | Skeletal Army + Giant Skeleton |

## Passive Items (30+)

### Stat Boosters
- Whetstone - +15% damage
- Running Shoes - +10% move speed
- Hollow Heart - +20% max HP
- Empty Tome - -10% cooldowns
- Lucky Clover - +10% luck (affects crit, drops)
- Magnet - +30% pickup radius
- Crown - +10% XP gain

### Special Effects
- Garlic Necklace - Enemies take DOT near you
- Thorns - Reflect 20% damage taken
- Revival Pendant - One free death per run
- Time Piece - Everything 10% slower (except you)
- Berserker's Blood - +30% damage when below 30% HP
- Vampiric Fang - 1% lifesteal on all damage
- Greed Ring - +25% gold drops

### Build Enablers (Unique Effects)
- Spell Eater - Magic weapons can crit
- Combo Counter - Damage increases with consecutive hits
- Elemental Mastery - All damage gets random element
- The Meat - Massive HP, can't dodge
- Glass Cannon - +50% damage, -50% HP
- Pacifist's Irony - Enemies damage each other near you

## Enemy Types (30+)

### Common Enemies (Swarmers)
- **Shambler** - Basic zombie, slow, walks toward player
- **Skeleton Footman** - Slightly faster, slightly smarter
- **Rat Swarm** - Very fast, very weak, comes in large numbers
- **Ghost Wisp** - Floats, ignores terrain collision
- **Cultist Initiate** - Ranged, throws weak projectiles

### Uncommon Enemies
- **Skeleton Knight** - Armored, takes reduced damage
- **Plague Bearer** - Explodes on death, leaves poison
- **Banshee** - Screams, slows player temporarily
- **Hell Hound** - Fast charger, pauses before lunging
- **Necromancer** - Summons skeletons, high priority target

### Elite Enemies (Spawn after 5 mins)
- **Bone Titan** - Giant skeleton, lots of HP, sweeping attacks
- **Death Knight** - Mounted, charges, very dangerous
- **Lich Apprentice** - Teleports, casts seeking projectiles
- **Abomination** - Slow but splits into smaller enemies on death
- **Champion Variants** - Any common enemy but larger, with modifier

### Boss Enemies (5 mins, 10 mins, 15 mins, 20 mins)
1. **The Reanimated Accountant** (5 min)
   - Attacks with stacks of paperwork
   - Summons spreadsheet minions
   - Death quote: "My calculations... were... off..."

2. **Lord Ratticus Supreme** (10 min)
   - Giant rat king, summons waves of rats
   - Ground pound creates shockwaves
   - Death quote: "You've made a powerful enemy... of the rat lobby!"

3. **The Comically Large Skeleton** (15 min)
   - It's a skeleton. It's comically large.
   - Bone projectile rain, grabbing attacks
   - Death quote: "I have... a bone to pick... no wait I'm dead"

4. **Jeff from HR** (Final Boss - 20 min)
   - Demonic corporate entity
   - Multiple phases, summons all enemy types
   - Mandatory meeting attacks (traps player)
   - Death quote: "But... my... quarterly reviews..."

## Progression Systems

### Run Progression (Per Run)
- Level 1-10: Basic enemies, build foundation
- Level 11-25: Elites appear, synergies forming
- Level 26-40: Boss patterns, build complete
- Level 41+: Victory lap, maximum chaos

### Meta Progression (Permanent)
**Gold Upgrades (Spend gold earned from runs):**
- Max HP +5 (repeatable, scales)
- Base Damage +2% (repeatable, scales)
- Move Speed +1% (repeatable, scales)
- XP Gain +2% (repeatable, scales)
- Starting Gold +10 (repeatable)
- Luck +1% (repeatable)
- Revival +1 (max 3 total)

**Character Unlocks (Achievement-based):**
- Kill X enemies total
- Reach X minute mark
- Defeat specific boss
- Collect X gold total
- Die X times
- Win with specific character
- Find secret areas

### Achievements (50+)
- "First Blood" - Kill your first enemy
- "Not Bad" - Survive 5 minutes
- "Actually Decent" - Survive 10 minutes
- "Show Off" - Survive 20 minutes
- "Overachiever" - Complete a run
- "Middle Management" - Defeat your first boss
- "Corporate Restructuring" - Defeat Jeff from HR
- "Collector" - Have 6 weapons at once
- "It Wasn't Me" - Let summons kill 1000 enemies
- "Glass Cannon IRL" - Win with less than 50 max HP
- "Immortal Until I Wasn't" - Die with 3 revivals
- "Found It" - Discover a secret character
- "Completionist" - Unlock all characters

## Audio Design

### Music
- Menu: Ominous orchestral with silly undertones
- Gameplay: Dynamic intensity based on enemy count
- Boss: Heavy metal/orchestral hybrid
- Victory: Triumphant but slightly anticlimactic
- Death: Sad trombone followed by dramatic sting

### Sound Effects
- Weapon impacts: Satisfying thuds and splatters
- Level up: Angelic choir (slightly off-key)
- XP pickup: Crystalline dings
- Boss entrance: Wilhelm scream (reversed)
- Menu navigation: Parchment shuffling

## Visual Style

### Art Direction
- Dark fantasy environments with splashes of absurd color
- Characters: Exaggerated proportions, readable at small size
- Enemies: Spooky but not truly scary
- Effects: Over-the-top particles, screen shake
- UI: Medieval parchment aesthetic with modern readability

### Screen Effects
- Hit flash: White overlay on damaged enemies (2 frames)
- Screen shake: On kills, scales with damage
- Hitstop: Brief freeze on heavy hits (3-4 frames)
- Damage numbers: Float up with color coding
- Level up: Golden flash, time slowdown

## Technical Specifications

### Performance Targets
- 60 FPS minimum with 500+ enemies
- 1000+ simultaneous projectiles
- Load times under 3 seconds

### Minimum Requirements
- OS: Windows 10
- CPU: Dual-core 2GHz
- RAM: 4GB
- GPU: Integrated graphics (Intel HD 4000+)
- Storage: 500MB

### Save System
- Auto-save meta progression after each run
- Save unlock progress immediately
- Store: Gold, unlocks, achievements, stats
- Location: User data folder (Steam Cloud ready)
