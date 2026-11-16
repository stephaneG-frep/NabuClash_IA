enum ProviderId { openai, anthropic, gemini, mistral, grok, perplexity }

extension ProviderLabel on ProviderId {
  String get label => const [
    'OpenAI / ChatGPT',
    'Anthropic / Claude',
    'Google Gemini',
    'Mistral AI',
    'xAI / Grok',
    'Perplexity',
  ][index];
  String get symbol => const ['◎', '✳', '✦', 'M', '𝕏', '✺'][index];
}

const styles = [
  '😏 Sarcastique',
  '😈 Effronté',
  '😂 Comique',
  '🙃 Ironique',
  '🎩 Élégant',
  '🧠 Intelligent',
  '🧊 Glacial',
  '🎭 Théâtral',
  '🤪 Absurde',
  '😐 Pince-sans-rire',
  '🥂 Gentleman assassin',
  '⚡ Courte et efficace',
  '🪶 Subtile',
  '🤣 Autodérision',
  '🤝 Diplomatique',
  '😜 Taquine',
  '🎲 Surprends-moi',
];
const personalities = [
  '🎩 Classe',
  '😏 Insolent',
  '🤡 Comique',
  '🧠 Intello',
  '🧊 Glacial',
  '🎭 Théâtral',
  '🌀 Absurde',
];
const people = [
  'Ami',
  'Collègue',
  'Patron',
  'Famille',
  'Partenaire',
  'Inconnu',
  'Réseaux sociaux',
  'Autre',
];
const contexts = [
  'Travail',
  'Amis',
  'Famille',
  'Couple',
  'Internet',
  'Conversation publique',
  'Conversation privée',
];
const modifiers = [
  '😂 Plus drôle',
  '😏 Plus sarcastique',
  '🧠 Plus intelligent',
  '🪶 Plus subtil',
  '⚡ Plus court',
  '🔥 Plus culotté',
  '😇 Moins méchant',
  '🎲 Surprends-moi',
  '🔄 Complètement différent',
];

class Situation {
  final String text, context, person, setting, style;
  final int intensity;
  const Situation({
    required this.text,
    this.context = '',
    this.person = 'Ami',
    this.setting = 'Conversation privée',
    this.style = '😏 Sarcastique',
    this.intensity = 3,
  });
  Map<String, dynamic> toJson() => {
    'text': text,
    'context': context,
    'person': person,
    'setting': setting,
    'style': style,
    'intensity': intensity,
  };
  factory Situation.fromJson(Map<String, dynamic> j) => Situation(
    text: j['text'] as String,
    context: j['context'] as String? ?? '',
    person: j['person'] as String? ?? 'Ami',
    setting: j['setting'] as String? ?? 'Conversation privée',
    style: j['style'] as String? ?? styles.first,
    intensity: j['intensity'] as int? ?? 3,
  );
}

class Reply {
  final String text, style;
  final int intensity;
  const Reply(this.text, this.style, this.intensity);
  Map<String, dynamic> toJson() => {
    'text': text,
    'style': style,
    'intensity': intensity,
  };
  factory Reply.fromJson(Map<String, dynamic> j) => Reply(
    j['text'] as String,
    j['style'] as String? ?? 'Répartie',
    (j['intensity'] as num? ?? 3).toInt().clamp(1, 5),
  );
}

class Message {
  final String role, text;
  const Message(this.role, this.text);
  Map<String, dynamic> toJson() => {'role': role, 'content': text};
  factory Message.fromJson(Map<String, dynamic> j) =>
      Message(j['role'] as String, j['content'] as String);
}

class SavedReply {
  final String id, date, provider, model;
  final Situation situation;
  final Reply reply;
  bool favorite;
  SavedReply({
    required this.id,
    required this.date,
    required this.provider,
    required this.model,
    required this.situation,
    required this.reply,
    this.favorite = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'provider': provider,
    'model': model,
    'situation': situation.toJson(),
    'reply': reply.toJson(),
    'favorite': favorite,
  };
  factory SavedReply.fromJson(Map<String, dynamic> j) => SavedReply(
    id: j['id'],
    date: j['date'],
    provider: j['provider'],
    model: j['model'],
    situation: Situation.fromJson(Map<String, dynamic>.from(j['situation'])),
    reply: Reply.fromJson(Map<String, dynamic>.from(j['reply'])),
    favorite: j['favorite'] == true,
  );
}

class Conversation {
  final String id;
  final List<Message> messages;
  Conversation(this.id, [List<Message>? messages]) : messages = messages ?? [];
  String get title =>
      messages.isEmpty ? 'Nouvelle conversation' : messages.first.text;
  Map<String, dynamic> toJson() => {
    'id': id,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    j['id'],
    (j['messages'] as List)
        .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
}
