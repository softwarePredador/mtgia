bool supportsOpenAiStrictJsonSchema(String model) {
  final normalized = model.trim().toLowerCase();
  return normalized.startsWith('gpt-4o') ||
      normalized.startsWith('gpt-4.1') ||
      normalized.startsWith('gpt-5') ||
      normalized == 'chat-latest';
}

Map<String, int> openAiTokenLimitPayload({
  required String model,
  required int maxTokens,
}) {
  final normalized = model.trim().toLowerCase();
  final usesCompletionTokens =
      normalized.startsWith('gpt-5') ||
      normalized.startsWith('o1') ||
      normalized.startsWith('o3') ||
      normalized.startsWith('o4');
  return usesCompletionTokens
      ? {'max_completion_tokens': maxTokens}
      : {'max_tokens': maxTokens};
}

Map<String, dynamic> openAiStructuredResponseFormat({
  required String model,
  required String name,
  required Map<String, dynamic> schema,
}) {
  if (!supportsOpenAiStrictJsonSchema(model)) {
    return const {'type': 'json_object'};
  }
  return {
    'type': 'json_schema',
    'json_schema': {'name': name, 'strict': true, 'schema': schema},
  };
}

const openAiDeckGenerationSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'commander': {
      'anyOf': [
        {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'required': ['name'],
          'additionalProperties': false,
        },
        {'type': 'null'},
      ],
    },
    'cards': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'quantity': {'type': 'integer', 'minimum': 1},
        },
        'required': ['name', 'quantity'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['commander', 'cards'],
  'additionalProperties': false,
};

const openAiArchetypesSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'options': {
      'type': 'array',
      'minItems': 3,
      'maxItems': 3,
      'items': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'difficulty': {
            'type': 'string',
            'enum': ['Baixa', 'Média', 'Alta'],
          },
        },
        'required': ['id', 'title', 'description', 'difficulty'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['options'],
  'additionalProperties': false,
};

const _openAiRecommendationItemSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'card_name': {'type': 'string'},
    'reason': {'type': 'string'},
  },
  'required': ['card_name', 'reason'],
  'additionalProperties': false,
};

const openAiDeckRecommendationsSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'archetype': {'type': 'string'},
    'power_level': {'type': 'integer', 'minimum': 1, 'maximum': 5},
    'analysis': {'type': 'string'},
    'recommendations': {
      'type': 'object',
      'properties': {
        'add': {
          'type': 'array',
          'minItems': 5,
          'maxItems': 5,
          'items': _openAiRecommendationItemSchema,
        },
        'remove': {
          'type': 'array',
          'minItems': 5,
          'maxItems': 5,
          'items': _openAiRecommendationItemSchema,
        },
      },
      'required': ['add', 'remove'],
      'additionalProperties': false,
    },
  },
  'required': ['archetype', 'power_level', 'analysis', 'recommendations'],
  'additionalProperties': false,
};

const openAiDeckOptimizationSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'summary': {'type': 'string'},
    'swaps': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'out': {'type': 'string'},
          'in': {'type': 'string'},
          'category': {
            'type': 'string',
            'enum': [
              'Mana Ramp',
              'Card Draw',
              'Removal',
              'Synergy',
              'Land Base',
              'Win Condition',
              'Protection',
              'Board Wipe',
            ],
          },
          'reasoning': {
            'type': 'string',
            'description':
                'Must explicitly include Funcao, Risco, Curva, Preco and Bracket labels.',
          },
          'priority': {
            'type': 'string',
            'enum': ['High', 'Medium', 'Low'],
          },
        },
        'required': ['out', 'in', 'category', 'reasoning', 'priority'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['summary', 'swaps'],
  'additionalProperties': false,
};

const openAiDeckCompletionSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'summary': {'type': 'string'},
    'additions': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'reasoning': {'type': 'string'},
    'category_breakdown': {
      'type': 'object',
      'properties': {
        'lands': {'type': 'integer', 'minimum': 0},
        'ramp': {'type': 'integer', 'minimum': 0},
        'card_draw': {'type': 'integer', 'minimum': 0},
        'removal': {'type': 'integer', 'minimum': 0},
        'board_wipes': {'type': 'integer', 'minimum': 0},
        'synergy': {'type': 'integer', 'minimum': 0},
        'win_conditions': {'type': 'integer', 'minimum': 0},
        'protection': {'type': 'integer', 'minimum': 0},
      },
      'required': [
        'lands',
        'ramp',
        'card_draw',
        'removal',
        'board_wipes',
        'synergy',
        'win_conditions',
        'protection',
      ],
      'additionalProperties': false,
    },
  },
  'required': ['summary', 'additions', 'reasoning', 'category_breakdown'],
  'additionalProperties': false,
};

const openAiOptimizationCriticSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'approval_score': {'type': 'integer', 'minimum': 0, 'maximum': 100},
    'verdict': {
      'type': 'string',
      'enum': ['aprovado', 'aprovado_com_ressalvas', 'reprovado'],
    },
    'concerns': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'strong_swaps': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'weak_swaps': {
      'type': 'array',
      'items': {'type': 'string'},
    },
    'overall_assessment': {'type': 'string'},
  },
  'required': [
    'approval_score',
    'verdict',
    'concerns',
    'strong_swaps',
    'weak_swaps',
    'overall_assessment',
  ],
  'additionalProperties': false,
};

const openAiDeckAnalysisSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'synergy_score': {'type': 'integer', 'minimum': 0, 'maximum': 100},
    'strengths': {'type': 'string'},
    'weaknesses': {'type': 'string'},
  },
  'required': ['synergy_score', 'strengths', 'weaknesses'],
  'additionalProperties': false,
};
