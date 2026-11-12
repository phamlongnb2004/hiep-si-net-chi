// Lời nhắc vẽ cho bản đồ 2-5 (đợt 1). Chạy trong tab ChatGPT: dán nội dung, gọi buildQ() rồi đẩy vào hàng đợi.
const STYLE = 'same cute chibi 2D game art style as before (thick dark outline, cel shading, bright saturated colors)';
const CELL = 'in a 4x2 grid read left-to-right then top-to-bottom, side view facing RIGHT, the character the SAME size in every cell, feet on the same baseline, plain pure white background, wide white gaps between frames, no grid lines, no ground shadow, no text';
const M = [
 { id: 'm02', theme: 'Golden Sand Desert (rolling golden dunes, sandstone ruins, palm oasis, cacti, hot clear sky)',
   mobs: [['scorp', 'Sand Scorpion: chunky sandy-orange scorpion with big pincers and a curled stinger tail', 'scuttle walk on 6 legs', 'stinger tail stab forward'],
          ['camel', 'Spiky Camel: grumpy camel with cactus-like spikes on its humps and a desert scarf', 'walk', 'head-butt charge forward'],
          ['mummy', 'Mummy: chibi mummy wrapped in old bandages with glowing eyes and loose bandage ends', 'shambling walk', 'swing arm forward whipping a bandage']],
   boss: ['Emperor Scorpion: huge golden-armored scorpion king with a jeweled crown, giant pincers and a purple venom stinger',
          'idle breathing stance, claws opening and closing, tail swaying', 'scuttle walk on 6 legs',
          ['tail raised high then stabbing forward hard (venom sting)', 'spinning in place kicking up a sand vortex (body only)', 'burrowing down into the sand then bursting back up (body only, show sand mound)']],
   fx: [['sting', 'purple venom splash cone shooting forward with toxic droplets, growing then fading, horizontal shape'],
        ['sandstorm', 'swirling sand tornado column of golden sand and small pebbles, growing then fading, tall vertical shape'],
        ['erupt', 'sand eruption bursting up from the ground with sand chunks and dust, growing then fading, ground-level shape']],
   kit: { mid: 'distant sand dunes with sandstone ruins, a few palms and an oasis', ground: 'top edge = rippled golden sand with small pebbles and tiny dry grass, body = layered sandstone strata',
          parts: 'sandy top, layered sandstone side', plat: 'a FLOATING PLATFORM: flat sandstone slab with sand on top and wooden beams under it',
          props: '(1) tall palm tree, (2) tall saguaro cactus, (3) dry desert bush, (4) sandstone boulder, (5) broken sandstone pillar, (6) pile of clay pots, (7) wooden signpost, (8) sandstone ruin archway gate (big)',
          cave: 'inside a vast sandstone tomb hall of the scorpion king: golden treasure piles, hieroglyph pillars, sand falling from cracks, torches' } },
 { id: 'm03', theme: 'Red Rock Canyon (red mesas, layered rock cliffs, dry shrubs, old wooden mine scaffolds, warm sunset sky)',
   mobs: [['eagle', 'Canyon Eagle: brown-and-white eagle with a fierce look, wings spread', 'flying wing-flap loop (hovering in air)', 'diving talon strike forward'],
          ['lizard', 'Rock Lizard: stocky red-orange lizard with rocky plates on its back', 'walk on 4 legs', 'tail whip swing'],
          ['pebble', 'Pebble Golem: small round golem made of grey and red pebbles with glowing orange eyes', 'stomping walk', 'punch forward with a rock fist']],
   boss: ['Red Mountain Golem: huge golem of red canyon rock with glowing magma cracks, moss on shoulders, massive fists',
          'idle breathing stance, magma cracks glowing', 'heavy stomping walk',
          ['lifting a big boulder overhead then throwing it forward (body only, boulder in hands)', 'raising one foot then stomping the ground hard (body only)', 'crossing arms as rock armor plates bulge out then bursting them outward (body only)']],
   fx: [['boulder', 'big red boulder crashing down from above and shattering into rocks and dust, growing then fading, ground-level shape'],
        ['quake', 'ground crack line splitting with red rock shards jutting up and dust, growing then fading, wide horizontal ground shape'],
        ['shards', 'burst of flying red rock shards and orange sparks outward in a ring, growing then fading, wide shape']],
   kit: { mid: 'layered red rock cliffs and mesas with dry shrubs and an old wooden mine scaffold', ground: 'top edge = dusty red earth with small rocks and dry grass tufts, body = layered red and orange rock strata',
          parts: 'red rock top with dry grass, layered red rock side', plat: 'a FLOATING PLATFORM: wooden mine scaffold plank on red rock with ropes',
          props: '(1) tall red rock spire, (2) dead twisted tree, (3) dry tumbleweed shrub, (4) red boulder, (5) stacked stone cairn, (6) old wooden mine cart with ore, (7) wooden signpost, (8) mine entrance gate with wooden beams (big)',
          cave: 'inside a huge red rock cavern forge of the golem: glowing magma cracks, giant stone anvil, hanging chains, crystals in the walls' } },
 { id: 'm04', theme: 'Cherry Blossom Valley (pink sakura trees, falling petals, wooden Japanese bridges, koi pond, soft spring sky)',
   mobs: [['ffox', 'Blossom Fox: small orange fox with pink cherry-blossom flowers on its tail and ears', 'trotting run', 'pounce bite forward'],
          ['pixie', 'Petal Pixie: tiny fairy with pink petal wings and a flower hat', 'flying flutter loop (hovering in air)', 'casting a petal blast forward with both hands'],
          ['ncat', 'Ninja Cat: chibi cat in a dark blue ninja outfit with a pink scarf and a small katana', 'sneaky run', 'katana slash forward']],
   boss: ['Nine-Tailed Fox: elegant white fox spirit with nine flowing tails tipped with pink fire, golden ornaments',
          'idle stance, nine tails waving gently', 'graceful running',
          ['spinning gracefully with tails fanned out casting petals (body only)', 'opening mouth and tails toward front to cast fox fire (body only)', 'crouching then making a magic hand-seal pose with glowing eyes (body only)']],
   fx: [['petals', 'swirling storm of pink cherry petals with sparkles falling down, growing then fading, ground-level shape'],
        ['foxfire', 'stream of pink-and-blue fox fire balls shooting forward, growing then fading, horizontal shape'],
        ['smoke', 'magic puff of pink smoke and sparkles (clone appearing), growing then fading, round shape']],
   kit: { mid: 'rows of pink sakura trees, a wooden pagoda and a red arched bridge in the distance', ground: 'top edge = green grass with fallen pink petals and tiny flowers, body = brown earth with smooth river stones',
          parts: 'grassy top with pink petals, earth and stone side', plat: 'a FLOATING PLATFORM: wooden walkway plank with a small red railing and petals',
          props: '(1) big pink sakura tree, (2) small sakura tree, (3) pink azalea bush, (4) mossy round rock, (5) stone lantern with petals, (6) red arched wooden bridge piece, (7) wooden signpost, (8) shrine gate covered in sakura flowers (big)',
          cave: 'inside a moonlit spirit shrine hall of the nine-tailed fox: glowing paper lanterns, giant sakura tree with glowing petals, fox statues, mist' } },
 { id: 'm05', theme: 'Glowing Mushroom Forest (night, giant blue and purple glowing mushrooms, fireflies, moonlight, ferns)',
   mobs: [['gnome', 'Mushroom Gnome: little gnome with a big red-and-white mushroom cap hat and a tiny lantern', 'waddling walk', 'swing lantern forward'],
          ['firefly', 'Giant Firefly: chubby glowing firefly with a bright yellow-green belly lamp', 'flying buzz loop (hovering in air)', 'dive ram forward with glowing belly'],
          ['gsnail', 'Glow Snail: snail with a glowing blue crystal shell', 'slow sliding crawl', 'shell bash forward']],
   boss: ['Ancient Mushroom Mother: giant ancient mushroom spirit with a huge glowing purple cap, a wise face, root legs and vine arms',
          'idle swaying stance, cap glowing', 'slow root walking',
          ['shaking cap to puff out spores (body only)', 'raising vine arms to summon (body only)', 'slamming roots into the ground (body only)']],
   fx: [['spore', 'cloud of glowing purple-green poison spores drifting forward, growing then fading, horizontal shape'],
        ['sprout', 'little mushrooms popping out of the ground with sparkle and dirt, growing then fading, ground-level shape'],
        ['roots', 'twisting glowing roots bursting up from the ground in a row, growing then fading, ground-level shape']],
   kit: { mid: 'dark forest of giant glowing mushrooms with ferns and fireflies', ground: 'top edge = dark mossy grass with tiny glowing mushrooms, body = dark earth with roots and glowing crystals',
          parts: 'mossy top with tiny glowing mushrooms, dark earth side with roots', plat: 'a FLOATING PLATFORM: flat top of a giant blue glowing mushroom cap',
          props: '(1) giant glowing mushroom, (2) cluster of small glowing mushrooms, (3) glowing fern, (4) mossy rock, (5) glowing blue crystal, (6) tree stump house with a round door, (7) wooden signpost, (8) mushroom archway gate (big)',
          cave: 'inside a vast underground mushroom grotto of the mushroom mother: giant glowing mushrooms, glowing pool, hanging roots, floating spores' } },
];
function buildQ() {
  const Q = [];
  for (const m of M) {
    const p = (n, t) => Q.push([`${m.id}_${n}.png`, t]);
    const list = m.mobs.map((x, i) => `(${i + 1}) ${x[1]}`).join(', ');
    p('model', `NEW SET for another map (theme: ${m.theme}). CHARACTER MODEL SHEET in the ${STYLE}: 4 characters side by side on a plain pure white background, full body, side view facing RIGHT, no text: ${list}, (4) BOSS: ${m.boss[0]}, about 1.7x bigger than the others.`);
    for (const [k, d, mv, at] of m.mobs) {
      const nm = d.split(':')[0];
      p(k + '_move', `SPRITE SHEET of the ${nm} from the latest model sheet (same design, colors, proportions exactly): 8 frames of a looping ${mv} cycle, ${CELL}, no effects.`);
      p(k + '_atk', `SPRITE SHEET of the ${nm} from the latest model sheet (same design exactly): 8 frames of an attack animation: ${at} (wind-up, strike, follow-through, back to stance), ${CELL}, no effects.`);
    }
    const bn = m.boss[0].split(':')[0];
    p('boss_idle', `SPRITE SHEET of the BOSS ${bn} from the latest model sheet (same design exactly): 8 frames of a looping ${m.boss[1]}, ${CELL}, no effects.`);
    p('boss_move', `SPRITE SHEET of the BOSS ${bn} (same design exactly): 8 frames of a looping ${m.boss[2]} cycle, ${CELL}, no effects.`);
    m.boss[3].forEach((d, i) => p('boss_s' + (i + 1), `SPRITE SHEET of the BOSS ${bn} (same design exactly): 8 frames of a skill animation: ${d}, ${CELL}. Draw NO magic effects, the effects are drawn separately.`));
    for (const [k, d] of m.fx) p('fx_' + k, `EFFECT sprite sheet, NO character: 8 frames in a 4x2 grid read left-to-right then top-to-bottom, the effect centered in each cell at the same scale, plain pure white background, wide white gaps, no grid lines, no text, same cute chibi game art style with dark outline. ${d}.`);
    const MA = `Now MAP ART for the same game (same art style: painterly-cel 2D side-scroller, bright, thick dark outline on foreground objects). Theme: '${m.theme}'.`;
    p('k_far', `${MA} FAR BACKGROUND only: a wide landscape panorama of the distant scenery and sky for this theme. No foreground objects, no characters, no text. The left and right edges should match so it can tile horizontally. Landscape orientation.`);
    p('k_mid', `${MA} MID-GROUND STRIP only: one long horizontal strip of ${m.kit.mid}, occupying the lower part of the image, isolated on a PLAIN PURE WHITE background above and around it (nothing drawn in the sky area). Left and right edges match for tiling. Landscape orientation, no text.`);
    p('k_ground', `${MA} GROUND TILE STRIP only: a long horizontal ground band seen from the side, ${m.kit.ground}, isolated on PLAIN PURE WHITE background, left and right edges continue seamlessly (tileable). Landscape orientation, no text.`);
    p('k_parts', `${MA} THREE separate isolated objects on a PLAIN PURE WHITE background, spaced apart in one row, no text: (1) LEFT cliff edge piece: ${m.kit.parts}, dropping down on its LEFT side; (2) ${m.kit.plat}; (3) RIGHT cliff edge piece: mirror shape with the drop on its RIGHT side.`);
    p('k_props', `${MA} PROP SHEET: 8 separate isolated objects on a PLAIN PURE WHITE background, arranged in a 4x2 grid with big gaps, no text, side view: ${m.kit.props}.`);
    p('k_cave', `${MA} BOSS LAIR BACKGROUND only: ${m.kit.cave}. Wide landscape panorama, left and right edges match for tiling, no characters, no text.`);
  }
  return Q;
}
