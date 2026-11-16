// Shared contract for providers supporting native JSON schemas.
const replySchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'replies': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {
          'text': {'type': 'string'},
          'style': {'type': 'string'},
          'intensity': {'type': 'integer'},
        },
        'required': ['text', 'style', 'intensity'],
        'additionalProperties': false,
      },
    },
  },
  'required': ['replies'],
  'additionalProperties': false,
};
