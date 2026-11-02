# Animation specification — {{asset_id}} / {{state_direction}}

| Property | Specification |
|---|---|
| Design / Pixelorama master | {{same design_id and .pxo as other states}} |
| State / direction / tag | {{idle,walk,attack,hurt,death,ambient,play}} / {{direction}} / {{state_direction}} |
| Frame size / pivot | {{fixed canvas}} / {{fixed x,y from top-left}} |
| Timeline tag range | {{Pixelorama's displayed 1-based start..end}} |
| Export sheet indices | {{zero-based row-major indices, explicit playback order}} |
| FPS / per-frame durations | {{FPS}} / {{optional durations_ms array}} |
| Loop / exit behavior | {{loop or once; transition/final pose}} |
| Unique drawings / playback frames | {{actual count}} / {{count including reused drawings}} |
| Contact event | {{animation-local frame, time, physics tick; none if absent}} |
| Body / weapon / VFX relationship | {{matching contact and origins}} |

## Pose and timing chart

| Local frame (0-based) | Pose / material change | Duration (ms) | Foot/anchor | Event |
|---|---|---|---|---|
| {{index}} | {{visible change or explicit hold of frame N}} | {{ms}} | {{plant/shift}} | {{contact/none}} |

For constant duration, frame time is `1000 / FPS` ms. For varying duration, record every frame's milliseconds; in Godot the relative duration is `duration_ms * FPS / 1000`. The contact occurs at the sum of durations before the contact frame, then must match the game's actual physics clock. Existing gameplay timing wins over a generic drawing recipe.

## Starting points for a new family

Tune these to the brief; do not overwrite established combat timings.

| State | Typical initial plan | Key poses |
|---|---|---|
| Idle | 4 drawings at 4–6 FPS, loop | settle, inhale, settle variant, exhale; restrained local motion |
| Walk | 6 drawings at 8 FPS, loop, four directions | contact, passing, recoil, opposite contact, passing, recoil |
| Attack | 5–8 drawings, once | windup, anticipation, contact, follow-through, recovery |
| Hurt | 2–4 drawings, once | impact, recoil, regain balance |
| Death | 5–8 drawings, once | loss of support, fall, settle; final frame held by state logic |

All states retain silhouette identity, clothing, palette, light direction, proportions, frame size, and pivot. Include enough canvas for fall and weapon reach before drawing the family. Mirroring must preserve equipment handedness and lighting.

## Review record

Inspect 1× playback, slowed playback, last→first seam, idle↔walk, and action interruptions. Note grounded-foot drift, inconsistent volumes, clipping, mechanical timing, and VFX/contact mismatch. Do not count duplicate/linked cels as distinct drawings. Scripts only measure visible differences; art review decides whether they express useful motion.

Motion preview: {{file}}. In-engine capture/fixture: {{file}}. Measured frame counts/durations: {{report}}. Reviewer observations and pending work: {{details}}.
