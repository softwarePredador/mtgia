const commanderFallbackPolicyVersion =
    'commander_fallback_policy_v1_2026_05_28';

const commanderWeakFillerDenylist = <String>{
  'ancestral reminiscence',
  'bane\'s contingency',
  'body of knowledge',
  'cancel',
  'diviner\'s portent',
  'didn\'t say please',
  'dream fracture',
  'dreamstone hedron',
  'forced fruition',
  'palladium myr',
  'prismatic lens',
  'sisay\'s ring',
  'silver myr',
  'stonespeaker crystal',
  'ur-golem\'s eye',
};

const commanderPremiumFillerNames = <String>{
  'arcane denial',
  'arcane signet',
  'brainstorm',
  'chrome mox',
  'counterspell',
  'cyclonic rift',
  'fact or fiction',
  'fierce guardianship',
  'force of negation',
  'force of will',
  'grim monolith',
  'lightning greaves',
  'mana drain',
  'mana vault',
  'mental misstep',
  'mind stone',
  'mox diamond',
  'mystical tutor',
  'negate',
  'pact of negation',
  'ponder',
  'preordain',
  'rhystic study',
  'sol ring',
  'swan song',
  'swiftfoot boots',
  'thassa\'s oracle',
  'thought vessel',
};

const commanderCompletionStapleNames = <String>[
  'Sol Ring',
  'Arcane Signet',
  'Mind Stone',
  'Fellwar Stone',
  'Swiftfoot Boots',
  'Lightning Greaves',
  'Command Tower',
  'Demonic Tutor',
  'Vampiric Tutor',
  'Rhystic Study',
  'Necropotence',
  'Cyclonic Rift',
  'Swords to Plowshares',
  'Anguished Unmaking',
  'Beast Within',
  'Nature\'s Claim',
  'Counterspell',
  'Mana Drain',
  'Fact or Fiction',
  'Ponder',
  'Preordain',
  'Brainstorm',
  'Signet',
  'Talisman',
  'Dark Ritual',
  'Reanimate',
  'Animate Dead',
  'Eternal Witness',
  'Regrowth',
  'Hero\'s Downfall',
  'Mortify',
  'Path to Exile',
  'Generous Gift',
  'Chaos Warp',
  'Krosan Grip',
  'Disenchant',
  'Return to Nature',
  'Mana Leak',
  'Force of Will',
  'Force of Negation',
  'Teferi\'s Protection',
  'Toxic Deluge',
  'Blasphemous Act',
  'Boardwipe',
  'Draw',
  'Ramp',
  'Removal',
];

const universalCommanderFallbackNames = <String>[
  'Sol Ring',
  'Arcane Signet',
  'Command Tower',
  'Mind Stone',
  'Wayfarer\'s Bauble',
  'Swiftfoot Boots',
  'Lightning Greaves',
  'Swords to Plowshares',
  'Path to Exile',
  'Beast Within',
  'Generous Gift',
  'Counterspell',
  'Negate',
  'Arcane Denial',
  'Brainstorm',
  'Swan Song',
  'Mystical Tutor',
  'Cyclonic Rift',
  'Rhystic Study',
  'Ponder',
  'Preordain',
  'Fact or Fiction',
  'Read the Bones',
  'Cultivate',
  'Kodama\'s Reach',
  'Farseek',
  'Nature\'s Lore',
  'Three Visits',
];

const _baseCommanderFoundationNames = <String>{
  'The One Ring',
  'Fellwar Stone',
  'Swiftfoot Boots',
  'Mystic Remora',
  'Swan Song',
  'An Offer You Can\'t Refuse',
};

const _monoBlueCommanderFoundationNames = <String>{
  'Fabricate',
  'Merchant Scroll',
  'Muddle the Mixture',
  'Pongify',
  'Rapid Hybridization',
  'Reality Shift',
  'Resculpt',
  'Spell Pierce',
  'Solve the Equation',
  'Windfall',
  'Whir of Invention',
};

const _monoBlueComboControlFoundationNames = <String>{
  'High Tide',
  'Jace, Wielder of Mysteries',
  'Long-Term Plans',
  'Personal Tutor',
  'Transmute Artifact',
  'Tezzeret the Seeker',
};

const _monoBlueProliferatePhyrexianFoundationNames = <String>{
  'Contentious Plan',
  'Experimental Augury',
  'Inexorable Tide',
  'Prologue to Phyresis',
  'Tekuthal, Inquiry Dominus',
  'Tezzeret\'s Gambit',
  'Thrummingbird',
};

Set<String> commanderFoundationNamesFor({
  required Set<String> commanderColorIdentity,
  required String targetArchetype,
  required String? detectedTheme,
}) {
  final names = <String>{..._baseCommanderFoundationNames};
  final identity = commanderColorIdentity.map((e) => e.toUpperCase()).toSet();
  final archetype = targetArchetype.toLowerCase();
  final theme = (detectedTheme ?? '').toLowerCase();

  if (identity.length == 1 && identity.contains('U')) {
    names.addAll(_monoBlueCommanderFoundationNames);

    if (archetype.contains('combo') || archetype.contains('control')) {
      names.addAll(_monoBlueComboControlFoundationNames);
    }

    if (theme.contains('proliferate') || theme.contains('phyrexian')) {
      names.addAll(_monoBlueProliferatePhyrexianFoundationNames);
    }
  }

  return names;
}
