# Higher Ground (Turkish title: Daha Yukarı)

## 1. Pitch
A lonely penguin walks away from a melting colony, looking for higher and colder ground. On the way up it finds traces of humans and slowly turns from "nothing matters" into "something might". A short 2.5D climbing game with dry humor and an emotional arc.

Event: GameUP Türkiye Oyun Hackathonu, 30 October to 1 November 2026. Solo entry. Theme: climate change, COP31 Türkiye (Antalya). Submission deadline 1 November 23:59. The game must be at demo stage.

Focus areas covered:
1. Oceans and Seas (chapter 1)
2. Zero Waste (chapter 2)
3. Climate Change Focused Education (info cards, monologue, endings)
4. Renewable Energy (chapter 3 lamp, optional)

## 2. Pillars
1. Short and polished. 10 to 12 minutes total. No game over, only respawn.
2. Learn by playing, not by lecture. One verified fact per card, one line each.
3. Dry humor first, feeling second. The penguin's inner voice carries the story.
4. One verb per chapter: jump (1), carry and sort (2), climb and decide (3).

## 3. Look and platform
1. 2.5D: 3D low poly models, perspective camera with low FOV, locked to the z = 0 plane, toon shading with outlines. Details in skill toon_2_5d_look.
2. PC (Windows). Web export is optional.
3. Input: A and D or arrows to move, Space to jump, E to interact, Esc to pause. Gamepad is optional.
4. Languages: English and Turkish, switch from the main menu and pause menu.

## 4. Core systems

### Heat (0.0 to 1.0)
1. Rises in sunlit zones and on warm ground, falls in shade and snow.
2. At 0.7 or more: movement slows slightly and the screen shimmers.
3. At 1.0: the penguin overheats and respawns at the last checkpoint. No lives, no penalty beyond the time lost.
4. Sources and sinks are HeatZone areas with a rate per second. Tunables in data/tuning.tres.

### Hope (0 to 100)
1. Starts at 10. It is a narrative meter, never a fail state.
2. Sources: fact card +2, correct sort +3, chick helped +15, seed planted +10, lamp connected +15. Wrong sort gives 0.
3. Drives: monologue tone variant, color grading (gray and cool to warm and saturated), and the ending.
4. Ending thresholds: under 35 is LOW, 35 to 69 is MID, 70 or more is HIGH. Tunable.

### Monologue
1. Short subtitle lines shown at triggers. No voice acting.
2. Keys in translations/strings.csv with prefix MONO_. Tone is deadpan and a little nihilist, slowly warming.
3. Tone must be original. Do not quote or imitate any specific documentary or meme text.

### Choices (3 total)
1. Chapter 1: a chick stuck on a shrinking floe. Help it (detour with a jump challenge) or walk on.
2. Chapter 2: a seed in the litter. Plant it on a bare patch or leave it.
3. Chapter 3: a solar lamp in the old hut. Connect it or sit down.

## 5. Chapters

### Chapter 1: Shore (Oceans and Seas)
1. Verb: jump with timing.
2. Ice tiles melt after the penguin stands on them (faster in sun). They respawn after a delay.
3. Sun patches heat the penguin, iceberg shade cools it. Plan routes between shade spots.
4. Beats: leave the colony, melting ice section, chick choice, climb off the shore.
5. Info cards: sea ice and penguins, species moving to higher ground.
6. Checkpoints: 3 cairns.

### Chapter 2: Slope (Zero Waste)
1. Verb: carry and sort.
2. Litter lies along the slope. Each item shows a type icon (paper, plastic, glass). Carry one item at a time above the head.
3. Sorting stations have three bins: paper blue, plastic yellow, glass green (Turkish recycling colors, verify before shipping). Press E near the right bin to sort.
4. Trash piles block the path. Sorting a required count (for example 3) opens the gate. Two gates in the chapter.
5. Bins use icon plus color, so the game stays readable for color blind players.
6. Beats: quiet start, first litter, first station and gate, seed choice, second station and gate, forest edge.
7. Info cards: plastic in remote places, sorting at the source, Zero Waste Day.

### Chapter 3: Summit (Climate Education and Renewable Energy)
1. Verb: climb and decide.
2. Steeper vertical sections, narrow ledges, light wind gusts that push sideways. Heat is low, the cold is the mood.
3. At the top: an old research hut and, in the distance, a road and a town. Nothing is far.
4. Lamp choice, then a slow camera pull back and the ending text for the current hope tier.
5. Info card: renewable energy growth.
6. End card: "Climate action starts where you stand." followed by the END_COP31 line (plain text, no logos).

## 6. Endings (same scene, different text, grade, and music layer)
1. LOW, Walked Away: it keeps walking. Bittersweet.
2. MID, Looked Back: it sees the colony and the problem as small enough to start.
3. HIGH, Went Back Down: it goes back to tell the others.
After the ending: credits, then Thanks for playing, then back to the main menu.

## 7. UI
1. Main menu: Play, Settings (language, volume), Quit.
2. HUD: heat bar (left), hope icon with fill (right), carried item icon, small control hints that fade.
3. Pause: Resume, Settings, Restart, Main Menu.
4. Fact card: small panel with the fact and a Source line, auto closes.
5. Choice panel: prompt and two buttons, game keeps running softly paused.

## 8. Audio
Wind ambience, snow steps, jump and land, ice crack, pickup, correct sort chime, wrong sort soft buzz, UI click, one calm music track with a warm layer that fades in as hope rises. CC0 or credited only.

## 9. Scope control
Must: player movement and camera, chapter 1 with melting ice and heat, hope and monologue, chapter 2 with two gates, chapter 3 short, localization, HUD and menus, one ending scene with three text tiers, Windows build.
Should: toon shader and outlines, background layers, sfx and music, info cards, particles.
Could: belly slide, gamepad, web export, second chick, more litter types.
Won't: voice acting, multiplayer, save slots, cutscene animations.
Cut order if late: Could, then chapter 3 becomes a short walk to the hut, then particles, then music layer.

## 10. Judging criteria map
1. Odak Tema: climate story, three focus areas, verified facts.
2. Yaratıcılık and Özgünlük: penguin on a climate migration, humor, hope meter that changes the world color.
3. Oyun Tasarımı and Oynanabilirlik: one verb per chapter, no fail state, short and clear.
4. Teknik İşlevsellik: stable build, both languages, no console errors.
5. Sunum and Etkili İletişim: template filled, screenshots, a 60 to 90 second demo video if allowed.
6. Zaman Yönetimi: keep the milestone log in docs/TASKS.md.
7. Takım and Motivasyon: solo, say it clearly, show the process.
