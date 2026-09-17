# Silky Smooth FPS Movement Roadmap

The movement system is built around one goal: keep traversal fast, fluid, expressive, and controlled by player intention.

## Current Movement

- [x] Walking
- [x] Sprinting
- [x] Jumping and falling
- [x] Crouching
- [x] Sliding
- [x] Dashing
- [x] Wall running
- [x] Wall jumping
- [x] Freeform grappling to arbitrary world geometry
- [x] Grapple momentum preservation
- [x] Grapple jump-cancel
- [x] Grapple cooldown and recovery
- [x] Grapple target indicator
- [x] Grapple rope visual

## Next Movement Systems

### 1. Ledge Vaulting

Allow the player to smoothly climb over low and medium-height ledges without stopping their movement.

Goals:

- Detect valid ledges automatically.
- Preserve horizontal momentum.
- Support sprinting into a vault.
- Support jumping into a vault.
- Blend naturally with sliding, wall running, wall jumping, and grappling.
- Avoid forced animation timing that takes control away from the player.

### 2. Ledge Mantling

Extend vaulting into taller climbable surfaces where a full vault is not appropriate.

Goals:

- Pull the player onto reachable surfaces.
- Use geometry-based detection rather than hand-placed climb points.
- Keep the transition quick and responsive.
- Preserve as much useful momentum as possible.

### 3. Air Control Expansion

Expand airborne movement so the player has more expressive control while falling, jumping, wall jumping, and grappling.

Goals:

- Tunable horizontal air acceleration.
- Momentum-aware steering.
- Strong but predictable directional control.
- Clean interaction with grapple movement.
- No floaty loss of control unless intentionally tuned.

### 4. Ground-to-Air Momentum Transitions

Make movement systems flow together more naturally when leaving the ground.

Goals:

- Preserve sprint momentum through jumps.
- Preserve slide momentum into jumps where appropriate.
- Make wall jumps inherit useful incoming momentum.
- Make grapples inherit and build on existing movement.
- Avoid artificial speed resets between movement states.

### 5. Dive / Ground Slam

Add a deliberate high-speed downward movement option that converts altitude into momentum.

Goals:

- Fast downward acceleration.
- Strong forward momentum while diving.
- Clean recovery back into normal movement.
- Potential interaction with slides, jumps, wall movement, and grapples.

### 6. Grapple Swing / Momentum Extension

Explore a secondary grapple behavior that allows the existing freeform grapple to become a momentum tool without replacing the direct pull.

Goals:

- Keep direct grappling as the primary one-button behavior.
- Preserve the current fast, direct reel-in.
- Allow momentum to naturally carry the player through and away from grapple points where appropriate.
- Avoid turning the system into a slow pendulum mechanic.

### 7. Glide / Controlled Falling

Add an aerial traversal system that sits between normal falling and full flight.

Goals:

- Reduce downward acceleration while gliding.
- Increase aerial steering.
- Allow forward momentum to carry through the glide.
- Support diving to trade altitude for speed.
- Integrate naturally with grappling and wall movement.

### 8. Advanced Aerial Movement

Build on gliding with additional high-speed aerial control once the core traversal systems are proven.

Potential systems:

- Dive acceleration.
- Air boosts.
- Momentum redirects.
- Grapple-to-glide transitions.
- Glide-to-grapple transitions.
- High-speed aerial recovery.

### 9. Flight

Only after the other traversal systems are established, investigate limited flight as an extension of the movement system rather than a replacement for it.

Goals:

- Preserve the importance of momentum and positioning.
- Keep flight responsive and skill-based.
- Avoid making every other traversal mechanic obsolete.
- Integrate with grappling, gliding, wall movement, and diving.

## Movement Design Rules

- Player intention comes first.
- Prefer geometry-based traversal over curated traversal points.
- Avoid unnecessary restrictions.
- Avoid hard movement-state locks.
- Preserve useful momentum between compatible systems.
- Movement should feel immediate without becoming unpredictable.
- Camera effects should communicate movement rather than obscure it.
- New systems should integrate with the existing movement architecture instead of duplicating it.
- Every new mechanic should be tunable through the Inspector.

## Long-Term Traversal Loop

The intended movement language is:

`Run → Jump → Vault → Wall Run → Wall Jump → Grapple → Jump Cancel → Glide → Dive → Grapple → repeat`

The exact route should always be determined by the player and the geometry of the world.
