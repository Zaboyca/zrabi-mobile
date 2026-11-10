class AboutHighlight {
  const AboutHighlight({required this.title, required this.body});

  final String title;
  final String body;

  factory AboutHighlight.fromJson(Map<String, dynamic> json) {
    return AboutHighlight(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class AboutSectionItems {
  const AboutSectionItems({
    required this.title,
    this.items = const [],
  });

  final String title;
  final List<AboutHighlight> items;

  factory AboutSectionItems.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return AboutSectionItems(
      title: json['title'] as String? ?? '',
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(AboutHighlight.fromJson)
              .toList()
          : const [],
    );
  }
}

class AboutAudience {
  const AboutAudience({
    required this.key,
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final String key;
  final String title;
  final String body;
  final List<String> bullets;

  factory AboutAudience.fromJson(Map<String, dynamic> json) {
    final raw = json['bullets'];
    return AboutAudience(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      bullets: raw is List
          ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}

class AboutFaqItem {
  const AboutFaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  factory AboutFaqItem.fromJson(Map<String, dynamic> json) {
    return AboutFaqItem(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class AboutPage {
  const AboutPage({
    required this.title,
    required this.headline,
    required this.lead,
    required this.introTitle,
    required this.introBody,
    this.introHighlights = const [],
    required this.advantages,
    required this.steps,
    this.audiencesTitle = '',
    this.audiences = const [],
    this.faqTitle = '',
    this.faqIntro = '',
    this.faq = const [],
  });

  final String title;
  final String headline;
  final String lead;
  final String introTitle;
  final String introBody;
  final List<AboutHighlight> introHighlights;
  final AboutSectionItems advantages;
  final AboutSectionItems steps;
  final String audiencesTitle;
  final List<AboutAudience> audiences;
  final String faqTitle;
  final String faqIntro;
  final List<AboutFaqItem> faq;

  factory AboutPage.fromJson(Map<String, dynamic> json) {
    final intro = json['intro'] as Map<String, dynamic>? ?? {};
    final highlights = intro['highlights'];
    final audiences = json['audiences'] as Map<String, dynamic>? ?? {};
    final faq = json['faq'] as Map<String, dynamic>? ?? {};
    final audienceItems = audiences['items'];
    final faqItems = faq['items'];

    return AboutPage(
      title: json['title'] as String? ?? 'О нас',
      headline: json['headline'] as String? ?? '',
      lead: json['lead'] as String? ?? '',
      introTitle: intro['title'] as String? ?? '',
      introBody: intro['body'] as String? ?? '',
      introHighlights: highlights is List
          ? highlights
              .whereType<Map<String, dynamic>>()
              .map(AboutHighlight.fromJson)
              .toList()
          : const [],
      advantages: AboutSectionItems.fromJson(
        json['advantages'] as Map<String, dynamic>? ?? {},
      ),
      steps: AboutSectionItems.fromJson(
        json['steps'] as Map<String, dynamic>? ?? {},
      ),
      audiencesTitle: audiences['title'] as String? ?? '',
      audiences: audienceItems is List
          ? audienceItems
              .whereType<Map<String, dynamic>>()
              .map(AboutAudience.fromJson)
              .toList()
          : const [],
      faqTitle: faq['title'] as String? ?? '',
      faqIntro: faq['intro'] as String? ?? '',
      faq: faqItems is List
          ? faqItems
              .whereType<Map<String, dynamic>>()
              .map(AboutFaqItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class ContactChallenge {
  const ContactChallenge({required this.token, required this.question});

  final String token;
  final String question;

  factory ContactChallenge.fromJson(Map<String, dynamic> json) {
    return ContactChallenge(
      token: json['token'] as String? ?? '',
      question: json['question'] as String? ?? '',
    );
  }
}

class ContactsPage {
  const ContactsPage({
    required this.email,
    required this.telegramBot,
    required this.telegramUrl,
    this.instagram,
    this.threads,
    this.vk,
    this.phone,
    this.address,
    this.formEnabled = true,
    this.challenge,
  });

  final String email;
  final String telegramBot;
  final String telegramUrl;
  final String? instagram;
  final String? threads;
  final String? vk;
  final String? phone;
  final String? address;
  final bool formEnabled;
  final ContactChallenge? challenge;

  List<({String key, String label, String url})> get socialLinks {
    final items = <({String key, String label, String url})>[];
    final ig = instagram?.trim() ?? '';
    final th = threads?.trim() ?? '';
    final vkUrl = vk?.trim() ?? '';
    if (ig.isNotEmpty) {
      items.add((key: 'instagram', label: 'Instagram', url: ig));
    }
    if (th.isNotEmpty) {
      items.add((key: 'threads', label: 'Threads', url: th));
    }
    if (vkUrl.isNotEmpty) {
      items.add((key: 'vk', label: 'ВКонтакте', url: vkUrl));
    }
    return items;
  }

  factory ContactsPage.fromJson(Map<String, dynamic> json) {
    final form = json['form'] as Map<String, dynamic>? ?? {};
    return ContactsPage(
      email: json['email'] as String? ?? '',
      telegramBot: json['telegram_bot'] as String? ?? '',
      telegramUrl: json['telegram_url'] as String? ?? '',
      instagram: json['instagram'] as String?,
      threads: json['threads'] as String?,
      vk: json['vk'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      formEnabled: form['enabled'] as bool? ?? true,
      challenge: form['challenge'] is Map<String, dynamic>
          ? ContactChallenge.fromJson(
              form['challenge'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
