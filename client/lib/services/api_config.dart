class AiApiConfig {
  AiApiConfig._();

  static const String apiKey =
      String.fromEnvironment('AI_API_KEY', defaultValue: 'sk-2vUtZioyGMgNBjQK4BEhyBaFoENy8rfjMkg4ucNUJTHNAldv');

  static const String videoSubmitUrl = 'https://jeniya.cn/v1/video/create';
  static const String videoFetchUrl = 'https://jeniya.cn/v1/video/query';

  static const String imageGenerateUrl =
      'https://jeniya.cn/v1/images/generations';

  static const String chatCompletionsUrl = 'https://jeniya.cn/v1/chat/completions';
  static const String responsesUrl = 'https://jeniya.cn/v1/responses';

  static const String musicSubmitUrl =
      'https://jeniya.cn/suno/submit/music';
  static const String musicFetchUrl = 'https://jeniya.cn/suno/fetch/';

  static Map<String, String> defaultHeaders({bool json = true}) {
    final headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
    };
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }
}
