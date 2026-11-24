/// DRAFT for Julia (REW-04, 23 Nov): a name for each stop inside a land, so
/// the child's stop and the next one read differently on the trail. The
/// content gives a land one name (catalogue.yaml, by world) and its stops
/// none; until it does, these stand in. Keyed by the land's name in the
/// child's world: the stops after its first, before its peak. A land's
/// first stop is the land's own name and its last is The peak. No numbers
/// (journey.yaml numbers_shown: none).
const draftStopNames = <String, List<String>>{
  // the Orchard, detective
  'Seedling Path': ['Seed Patch', 'Sprout Corner', 'Watering Can'],
  'Sapling Row': ['Little Fence', 'Tall Sprouts', 'Bird Bath'],
  'Orchard Gate': ['Apple Cart', 'Pear Arch', 'Fruit Stall'],
  'Old Oak Bridge': ['Acorn Bank', 'Mossy Steps', 'Owl Post'],
  'Twisty Tree': ['Knotty Roots', 'Swing Branch', 'Leafy Loop'],
  // the Star Fields, space
  'Launch Pad': ['Fuel Tank', 'Countdown Deck', 'Rocket Ramp'],
  'Moon Base': ['Crater Camp', 'Moon Buggy', 'Dust Dunes'],
  'Comet Gate': ['Ice Trail', 'Comet Tail', 'Star Arch'],
  'Asteroid Bridge': ['Rock Hop', 'Space Rope', 'Meteor Ledge'],
  'Twisty Nebula': ['Gas Cloud', 'Glow Swirl', 'Star Nursery'],
  // the Rainforest, wildlife
  'Wallaby Track': ['Hop Hollow', 'Grass Flat', 'Joey Burrow'],
  'Koala Grove': ['Gum Leaves', 'Sleepy Branch', 'Eucalypt Ring'],
  'Rainforest Gate': ['Fern Arch', 'Misty Steps', 'Cassowary Crossing'],
  'Vine Bridge': ['Rope Swing', 'Canopy Walk', 'Frog Pond'],
  'Twisty Vine': ['Tangle Path', 'Orchid Nook', 'Butterfly Loop'],
  // Harbour, by world
  'Bowl and Mug Dock': ['Rope Coil', 'Scale Shed', 'Gull Post'],
  'Heavy Crate Pier': ['Crane Hook', 'Barrel Stack', 'Anchor Spot'],
  'Twisty Scales': ['Weigh Station', 'Net Shed', 'Lighthouse Steps'],
  'Cargo Dock': ['Loading Ramp', 'Crate Bay', 'Drone Dock'],
  'Heavy Lift': ['Lift Arm', 'Pallet Row', 'Thruster Bay'],
  'Twisty Gravity': ['Float Zone', 'Spin Ring', 'Gravity Well'],
  'Wombat Scales': ['Burrow Bend', 'Log Scale', 'Muddy Bank'],
  'Croc Creek': ['Reed Bed', 'Sandbar', 'Lily Pads'],
  'Twisty River': ['River Bend', 'Pebble Ford', 'Platypus Pool'],
};

/// Stop [k] of the land named [land] (0 its first stop, before its peak),
/// or null when there is no name for it yet.
String? stopNameIn(String land, int k) {
  if (k == 0) return land;
  final names = draftStopNames[land];
  return names != null && k - 1 < names.length ? names[k - 1] : null;
}
