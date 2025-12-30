import '../models/question.dart';

/// 60件の日本語質問プール
/// 日付ベースのseedで毎日1つ選ばれる
class QuestionPool {
  static final List<Question> questions = [
    // 日常・感情系 (1-15)
    Question(questionId: 1, text: '今日一番嬉しかったことは何ですか？', category: '感情'),
    Question(questionId: 2, text: '今日一番大変だったことは何ですか？', category: '感情'),
    Question(questionId: 3, text: '今日、誰かに感謝したいことはありますか？', category: '感謝'),
    Question(questionId: 4, text: '今日の自分を一言で表すと？', category: '内省'),
    Question(questionId: 5, text: '今日、新しく気づいたことはありますか？', category: '発見'),
    Question(questionId: 6, text: '今日、笑った瞬間はありましたか？どんな時？', category: '感情'),
    Question(questionId: 7, text: '今日の天気と、あなたの気分は似ていましたか？', category: '内省'),
    Question(questionId: 8, text: '今日、もう一度やり直せるならどの瞬間？', category: '内省'),
    Question(questionId: 9, text: '今日、自分を褒めるとしたら何？', category: '自己肯定'),
    Question(questionId: 10, text: '今日、心に残った言葉はありますか？', category: '発見'),
    Question(questionId: 11, text: '今日、どんな音が印象に残っていますか？', category: '感覚'),
    Question(questionId: 12, text: '今日、時間を忘れて没頭したことはありますか？', category: '活動'),
    Question(questionId: 13, text: '今日、誰かのために何かしましたか？', category: '人間関係'),
    Question(questionId: 14, text: '今日、自分のために何かしましたか？', category: '自己ケア'),
    Question(questionId: 15, text: '今日、心がざわついた瞬間はありましたか？', category: '感情'),

    // 人間関係系 (16-25)
    Question(questionId: 16, text: '今日、一番長く話した人は誰ですか？', category: '人間関係'),
    Question(questionId: 17, text: '今日、誰かから学んだことはありますか？', category: '人間関係'),
    Question(questionId: 18, text: '今日、会いたいと思った人はいますか？', category: '人間関係'),
    Question(questionId: 19, text: '今日、誰かを応援したいと思いましたか？', category: '人間関係'),
    Question(questionId: 20, text: '今日、誰かに言いたかったけど言えなかったことは？', category: '人間関係'),
    Question(questionId: 21, text: '今日、誰かの笑顔を見ましたか？', category: '人間関係'),
    Question(questionId: 22, text: '今日、誰かと共有したい出来事はありましたか？', category: '人間関係'),
    Question(questionId: 23, text: '今日、誰かに助けられましたか？', category: '感謝'),
    Question(questionId: 24, text: '今日、家族のことを考えた瞬間はありましたか？', category: '人間関係'),
    Question(questionId: 25, text: '今日、友人のことを思い出した瞬間は？', category: '人間関係'),

    // 仕事・成長系 (26-35)
    Question(questionId: 26, text: '今日、一番集中できた時間帯はいつでしたか？', category: '生産性'),
    Question(questionId: 27, text: '今日、達成できたことを1つ挙げるなら？', category: '達成'),
    Question(questionId: 28, text: '今日、チャレンジしたことはありますか？', category: '成長'),
    Question(questionId: 29, text: '今日、「これは良い判断だった」と思うことは？', category: '内省'),
    Question(questionId: 30, text: '今日、もっと上手くやりたかったことはありますか？', category: '成長'),
    Question(questionId: 31, text: '今日、学んだことを一言でまとめると？', category: '学び'),
    Question(questionId: 32, text: '今日、仕事や勉強で嬉しかったことは？', category: '達成'),
    Question(questionId: 33, text: '今日、効率的にできたことはありますか？', category: '生産性'),
    Question(questionId: 34, text: '今日、新しいスキルを使いましたか？', category: '成長'),
    Question(questionId: 35, text: '明日の自分に引き継ぎたいことは？', category: '計画'),

    // 健康・ライフスタイル系 (36-45)
    Question(questionId: 36, text: '今日、体を動かしましたか？どんな風に？', category: '健康'),
    Question(questionId: 37, text: '今日、一番美味しかったものは何ですか？', category: '食事'),
    Question(questionId: 38, text: '今日、十分な休息は取れましたか？', category: '健康'),
    Question(questionId: 39, text: '今日、リラックスできた瞬間はありましたか？', category: '自己ケア'),
    Question(questionId: 40, text: '今日、外の空気を吸いましたか？', category: '健康'),
    Question(questionId: 41, text: '今日、体のどこかに疲れを感じていますか？', category: '健康'),
    Question(questionId: 42, text: '今日、水分は十分に取れましたか？', category: '健康'),
    Question(questionId: 43, text: '今日、朝起きた時の気分はどうでしたか？', category: '健康'),
    Question(questionId: 44, text: '今日、良い姿勢を意識できましたか？', category: '健康'),
    Question(questionId: 45, text: '今日の睡眠の質はどうでしたか？', category: '健康'),

    // 趣味・楽しみ系 (46-52)
    Question(questionId: 46, text: '今日、楽しみにしていたことはありましたか？', category: '趣味'),
    Question(questionId: 47, text: '今日、何か面白いものを見つけましたか？', category: '発見'),
    Question(questionId: 48, text: '今日、趣味の時間は取れましたか？', category: '趣味'),
    Question(questionId: 49, text: '今日、聴いた音楽はありますか？', category: '趣味'),
    Question(questionId: 50, text: '今日、読んだり観たりしたコンテンツは？', category: '趣味'),
    Question(questionId: 51, text: '今日、写真を撮りましたか？何の？', category: '趣味'),
    Question(questionId: 52, text: '今日、クリエイティブなことはしましたか？', category: '趣味'),

    // 未来・希望系 (53-60)
    Question(questionId: 53, text: '明日、楽しみにしていることはありますか？', category: '未来'),
    Question(questionId: 54, text: '今週中にやりたいことは何ですか？', category: '計画'),
    Question(questionId: 55, text: '今日の経験を、未来の自分にどう活かしたい？', category: '成長'),
    Question(questionId: 56, text: '今、一番叶えたい小さな願いは？', category: '願望'),
    Question(questionId: 57, text: '今日の自分から、昨日の自分へのメッセージは？', category: '内省'),
    Question(questionId: 58, text: '1ヶ月後の自分に伝えたいことは？', category: '未来'),
    Question(questionId: 59, text: '今日という日を漢字一文字で表すと？', category: '内省'),
    Question(questionId: 60, text: '今日の「ありがとう」を3つ挙げるなら？', category: '感謝'),
  ];

  /// 日付ベースのシードで質問を選択
  /// YYYYMMDD形式の数値をシードとして使用
  static Question getQuestionForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final index = seed % questions.length;
    return questions[index];
  }

  /// 別の質問を取得（質問変更時に使用）
  /// 元の質問とは異なる質問を返す
  static Question getAlternateQuestion(DateTime date, int currentQuestionId) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    // 異なる質問を選ぶため、シードに1を加える
    final alternateIndex = (seed + currentQuestionId + 17) % questions.length;
    final alternateQuestion = questions[alternateIndex];
    
    // もし同じ質問になってしまった場合は次の質問を返す
    if (alternateQuestion.questionId == currentQuestionId) {
      return questions[(alternateIndex + 1) % questions.length];
    }
    return alternateQuestion;
  }

  /// IDで質問を取得
  static Question? getQuestionById(int questionId) {
    try {
      return questions.firstWhere((q) => q.questionId == questionId);
    } catch (e) {
      return null;
    }
  }

  /// 全ての質問を取得
  static List<Question> getAllQuestions() => List.from(questions);

  /// 質問数を取得
  static int get questionCount => questions.length;
}
