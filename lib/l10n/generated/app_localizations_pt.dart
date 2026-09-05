// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Improvy';

  @override
  String get next => 'Seguinte';

  @override
  String get skip => 'Saltar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Concluído';

  @override
  String get close => 'Fechar';

  @override
  String get gotIt => 'Entendi';

  @override
  String get notNow => 'Agora não';

  @override
  String get retry => 'REPETIR';

  @override
  String get home => 'INÍCIO';

  @override
  String get start => 'COMEÇAR';

  @override
  String get startTraining => 'COMEÇAR A TREINAR';

  @override
  String get proOnly => 'SÓ PRO';

  @override
  String get free => 'GRÁTIS';

  @override
  String get modeDiatonic => 'Diatonic';

  @override
  String get modeChromatic => 'Chromatic';

  @override
  String get modeCustom => 'Custom';

  @override
  String get modeNoteToNumber => 'Note to Number';

  @override
  String get modeOfWhat => '…Of What?';

  @override
  String get modePocket => 'Pocket Mode';

  @override
  String get modeNormal => 'Normal';

  @override
  String get tierApprentice => 'Aprendiz';

  @override
  String get tierVirtuoso => 'Virtuoso';

  @override
  String get tierMaster => 'Mestre';

  @override
  String get onboardingTag => 'Treino mental';

  @override
  String get onboardingHeadline => 'Cada nota\né um\nnúmero.';

  @override
  String get onboardingPromise =>
      'Vê no instante o número por baixo de qualquer nota, nas doze tonalidades — sem contar, sem livro de teoria.';

  @override
  String get onboardingStart => 'Começar a treinar';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get termsOfService => 'Termos de serviço';

  @override
  String get explainerEyebrow => 'COMO FUNCIONA';

  @override
  String explainerStep(int n) {
    return '$n DE 3';
  }

  @override
  String get explainer1Title => 'Cada tecla\ntem um número.';

  @override
  String get explainer1Body =>
      'Estas são as sete notas de Dó maior. Os músicos chamam-lhes pelo número — o grau — porque o número diz o que a nota está a fazer, e funciona igual em todas as tonalidades.';

  @override
  String get explainer2Title => 'Muda de tonalidade.\nOs números ficam.';

  @override
  String get explainer2Body =>
      'Toca numa tonalidade e observa. As notas mudam, os números não: o 5 é sempre o 5. Aprende os números uma vez e tens as doze tonalidades.';

  @override
  String get explainer3Title => 'Experimenta.';

  @override
  String get explainer3Body =>
      'O jogo é isto. Rápido o suficiente, vezes suficientes, e deixa de ser aritmética para ser instinto — dois minutos por dia chegam.';

  @override
  String get letsGo => 'Vamos';

  @override
  String get summaryTitle => 'SESSÃO CONCLUÍDA';

  @override
  String get summaryPerfect => 'PONTUAÇÃO PERFEITA';

  @override
  String get summaryPassed => 'NÍVEL PASSADO';

  @override
  String get summaryCompleted => 'CONCLUÍDA';

  @override
  String get summaryNotYet => 'AINDA NÃO — CONTINUA';

  @override
  String get summaryCorrect => 'CERTAS';

  @override
  String get summaryErrors => 'ERROS';

  @override
  String get summaryTime => 'TEMPO';

  @override
  String get summaryAccuracy => 'PRECISÃO %';

  @override
  String get summaryModeMastery => 'DOMÍNIO DO MODO';

  @override
  String get summaryNextDifficulty => 'PRÓXIMA DIFICULDADE';

  @override
  String summaryUpsellTitle(String key) {
    return 'Essa foi a metade grátis de $key';
  }

  @override
  String get summaryUpsellBody =>
      'Chromatic acrescenta os cinco graus alterados — o resto da tonalidade.';

  @override
  String get paywallTitle => 'Improvy Pro';

  @override
  String get paywallLifetime => 'Licença vitalícia';

  @override
  String get paywallTagline => 'Cada tonalidade. Cada modo. Para sempre.';

  @override
  String get paywallEvery => 'Cada ';

  @override
  String get paywallForever => 'Para sempre.';

  @override
  String get paywallWhatYouGet => 'O que recebes, de músico para músico';

  @override
  String get paywallCta => 'Desbloquear acesso vitalício';

  @override
  String paywallPrice(String price) {
    return '$price · pagamento único';
  }

  @override
  String get paywallRestore => 'Restaurar';

  @override
  String get paywallNoPurchase => 'Nenhuma compra anterior encontrada';

  @override
  String get featChromatic => 'Chromatic Mode';

  @override
  String get featChromaticMeta => 'as 12 tonalidades';

  @override
  String get featNtn => 'Note to Number';

  @override
  String get featNtnMeta => 'cromático';

  @override
  String get featOfWhat => '…Of What?';

  @override
  String get featOfWhatMeta => 'os 15 graus';

  @override
  String get featPocket => 'Pocket Mode';

  @override
  String get featPocketMeta => 'os 12 graus';

  @override
  String get featCustom => 'Custom Mode';

  @override
  String get featCustomMeta => 'qualquer grau';

  @override
  String get featAdaptive => 'Dificuldade adaptativa';

  @override
  String get featAdaptiveMeta => 'automática';

  @override
  String get featAnalytics => 'Análises aprofundadas';

  @override
  String get featAnalyticsMeta => 'por tonalidade';

  @override
  String get storeNotReadyTitle => 'Loja indisponível';

  @override
  String get storeNotReadyBody =>
      'Neste momento não há nenhum produto disponível para compra. Tenta de novo daqui a pouco.';

  @override
  String get almostThereTitle => 'Quase lá';

  @override
  String get almostThereBody =>
      'O pagamento passou mas o PRO não foi ativado automaticamente. Toca em Restaurar compras daqui a instantes — não serás cobrado duas vezes.';

  @override
  String get billingUnavailableTitle => 'Compras indisponíveis';

  @override
  String get billingUnavailableBody =>
      'As compras na app não estão disponíveis neste dispositivo.';

  @override
  String get purchaseFailedTitle => 'Compra falhou';

  @override
  String get purchaseFailedBody =>
      'Algo correu mal ao contactar a loja. Tenta de novo.';

  @override
  String get notifPromptTitle => 'Para ficar';

  @override
  String get notifPromptBody =>
      'Um quiz rápido por dia mantém cada nota afiada e a tua sequência viva. Desliga quando quiseres.';

  @override
  String get notifPromptYes => 'Sim, lembra-me';

  @override
  String get homeAllKeys => 'DOMÍNIO DE TODAS AS TONALIDADES';

  @override
  String get homeSpecialModes => 'MODOS ESPECIAIS';

  @override
  String get homePickUp => 'CONTINUA ONDE FICASTE';

  @override
  String get homeTotalSessions => 'SESSÕES TOTAIS';

  @override
  String get homeAccuracy => 'PRECISÃO';

  @override
  String get homeTotalProgress => 'PROGRESSO TOTAL';

  @override
  String get homeNextMilestone => 'PRÓXIMO MARCO';

  @override
  String get homeMaxLevel => 'NÍVEL MÁXIMO!';

  @override
  String homeLevelShort(int n) {
    return 'NÍV $n';
  }

  @override
  String homeToNext(String pct, String animal) {
    return '$pct% para $animal';
  }

  @override
  String get homeNtnDesc => 'Dada uma nota, identifica o seu grau.';

  @override
  String get homeOfWhatDesc =>
      'Uma nota é um dado grau — diz a tónica. Harmoniza qualquer melodia.';

  @override
  String get homePocketDesc =>
      'Exercício áudio mãos-livres: uma voz pergunta, espera e diz a nota. Funciona com o ecrã desligado.';

  @override
  String get homeCustomDesc =>
      'Escolhe tonalidade, direção e os graus exatos a treinar.';

  @override
  String homeLastSession(String when) {
    return 'ÚLTIMA SESSÃO • $when';
  }

  @override
  String get homeResume => 'Retomar sessão';

  @override
  String get homeReadyTitle => 'Pronto para começar?';

  @override
  String get homeReadyBody => 'Escolhe uma tonalidade acima';

  @override
  String get homeGamesPlayed => 'JOGOS JOGADOS';

  @override
  String get homeChooseMode => 'Escolhe o modo';

  @override
  String get homeChooseModeSub => 'Escolhe como treinar hoje';

  @override
  String get homeDiatonicDesc => 'Domina as 7 notas da escala.';

  @override
  String get homeChromaticDesc => 'Desafia-te com os 12 meios-tons.';

  @override
  String homeLockedTier(String prev) {
    return 'Continua a treinar no modo $prev para desbloquear esta dificuldade.';
  }

  @override
  String get homeYourProgress => 'O TEU PROGRESSO';

  @override
  String get homeKeepTraining => 'CONTINUA';

  @override
  String get homeHandsFree => 'Áudio mãos-livres';

  @override
  String get homeJustNow => 'Agora mesmo';

  @override
  String homeMinutesAgo(int n) {
    return 'há $n min';
  }

  @override
  String homeHoursAgo(int n) {
    return 'há $n h';
  }

  @override
  String homeDaysAgo(int n) {
    return 'há $n d';
  }

  @override
  String get homeQuote1 =>
      'Todo o mestre já foi principiante. Vamos visualizar essas primeiras notas!';

  @override
  String get homeQuote2 =>
      'A meio caminho — os teus instintos estão a afinar. Continua!';

  @override
  String get homeQuote3 =>
      'O verdadeiro domínio vive nos detalhes. Confia no instinto e toca!';

  @override
  String homeKeyTileLabel(String key, int pct) {
    return 'Tonalidade de $key, $pct por cento';
  }

  @override
  String get setupTrainingSetup => 'CONFIGURAR TREINO';

  @override
  String get setupHarmonizeSetup => 'CONFIGURAR HARMONIZAÇÃO';

  @override
  String get setupPersonalized => 'PRÁTICA LIVRE · NÃO CONTA PARA O DOMÍNIO';

  @override
  String get setupHandsFree => 'MÃOS-LIVRES · ÁUDIO';

  @override
  String get setupSelectRootKey => 'Escolhe a tonalidade';

  @override
  String get setupSelectRootKeySub => 'Escolhe a base do teu treino.';

  @override
  String get setupSelectNote => 'Escolhe a nota';

  @override
  String get setupSelectNoteSub =>
      'A nota da melodia mantida durante toda a sessão.';

  @override
  String get setupIntensity => 'Intensidade';

  @override
  String get setupIntensityChromatic =>
      'Domina as 12 notas cromáticas desta tonalidade.';

  @override
  String get setupIntensityDiatonic =>
      'Concentra-te nas 7 notas da escala maior.';

  @override
  String get setupDifficulty => 'Dificuldade';

  @override
  String get setupDifficultySub =>
      'Mais dificuldade significa menos tempo para responder.';

  @override
  String get setupMode => 'Modo';

  @override
  String get setupModeNormalSub => 'Diz a nota de um grau, nesta tonalidade.';

  @override
  String get setupModeNtnSub => 'Diz o grau de uma nota, nesta tonalidade.';

  @override
  String get setupModeOfWhatSub =>
      'Uma nota mantida o tempo todo — diz a que tonalidade pertence.';

  @override
  String get setupSelectDegrees => 'Escolhe os graus';

  @override
  String get setupDegreesToAsk => 'Graus a perguntar';

  @override
  String get setupDegreesAll => 'Todos os graus, extensões incluídas.';

  @override
  String get setupDegreesChord => 'As quatro notas do acorde: 1, 3, 5, 7.';

  @override
  String get setupChord => 'Acorde';

  @override
  String get setupAll => 'Todos';

  @override
  String get setupQuickChord => 'ACORDE';

  @override
  String get setupQuickAll => 'TODOS';

  @override
  String get setupQuickDiatonic => 'DIATÓNICO';

  @override
  String get setupQuestions => 'Número de perguntas';

  @override
  String get setupQuestionsSub => 'Quantas perguntas nesta sessão?';

  @override
  String get setupKeys => 'Tonalidades';

  @override
  String get setupKeysSub => 'Treina uma tonalidade ou baralha as 12.';

  @override
  String get setupShuffleAll => 'Baralhar todas';

  @override
  String get setupOneKey => 'Uma tonalidade';

  @override
  String get setupDegrees => 'Graus';

  @override
  String get setupAnswerDelay => 'Pausa antes da resposta';

  @override
  String get setupLength => 'Duração';

  @override
  String get setupLengthSub => 'Número de perguntas (∞ = até parares).';

  @override
  String setupTierLocked(String tier) {
    return '$tier está bloqueado';
  }

  @override
  String setupTierLockedBody(int need, String prev, int have) {
    return 'Primeiro chega a $need certas em $prev. Estás em $have.';
  }

  @override
  String setupBest(int best, int cap) {
    return '$best/$cap RECORDE';
  }

  @override
  String setupKeyCellLabel(String key, int pct) {
    return '$key, $pct por cento';
  }

  @override
  String get trainerCorrect => 'CERTO';

  @override
  String get trainerWrong => 'ERRADO';

  @override
  String get trainerCorrectAnswer => 'RESPOSTA CERTA';

  @override
  String get trainerNote => 'NOTA';

  @override
  String get trainerKey => 'TONALIDADE';

  @override
  String get trainerDegree => 'GRAU';

  @override
  String get trainerProgress => 'PROGRESSO';

  @override
  String get trainerStreak => 'SEQUÊNCIA';

  @override
  String get trainerPianoKeyboard => 'TECLADO';

  @override
  String get trainerExitTitle => 'Terminar a sessão?';

  @override
  String trainerExitDaily(int done, int total) {
    return 'Uma tentativa por dia e o relógio continua a contar — se saíres agora, $done/$total é a tua pontuação até amanhã.';
  }

  @override
  String trainerExitEndless(int done) {
    return 'Vais em $done perguntas — sair termina a sessão e guarda a pontuação.';
  }

  @override
  String trainerExitBody(int done, int total) {
    return 'Vais em $done/$total — se saíres, a sessão termina aqui.';
  }

  @override
  String get trainerKeepPlaying => 'CONTINUAR';

  @override
  String get trainerQuit => 'SAIR';

  @override
  String get paywallLine1 => 'Cada tonalidade.';

  @override
  String get paywallLine2 => 'Cada modo.';

  @override
  String get paywallLine3 => 'Para sempre.';

  @override
  String get paywallRestoring => 'A restaurar…';

  @override
  String get paywallTerms => 'Termos';

  @override
  String get paywallPrivacy => 'Privacidade';

  @override
  String get animalSnail => 'Caracol';

  @override
  String get animalTurtle => 'Tartaruga';

  @override
  String get animalPenguin => 'Pinguim';

  @override
  String get animalRabbit => 'Coelho';

  @override
  String get animalFox => 'Raposa';

  @override
  String get animalHorse => 'Cavalo';

  @override
  String get animalFalcon => 'Falcão';

  @override
  String get animalCheetah => 'Chita';

  @override
  String get homeShuffleHandsFree => 'Baralhadas · mãos-livres';

  @override
  String homeTierDifficulty(String tier) {
    return 'Dificuldade $tier';
  }

  @override
  String get trainerGridView => 'GRELHA';

  @override
  String get trainerAccuracy => 'PRECISÃO';

  @override
  String get settingsTitle => 'DEFINIÇÕES';

  @override
  String get settingsAccountStatus => 'ESTADO DA CONTA';

  @override
  String get settingsFreePlan => 'Plano gratuito';

  @override
  String get settingsProPlan => 'Improvy Pro';

  @override
  String get settingsProSub => 'Todos os modos e tonalidades, desbloqueados.';

  @override
  String get settingsFreeSub =>
      'Toca para desbloquear todos os modos e tonalidades.';

  @override
  String get settingsActive => 'ATIVO';

  @override
  String get settingsTraining => 'TREINO';

  @override
  String get settingsAdaptive => 'Dificuldade adaptativa';

  @override
  String get settingsAdaptiveTag => 'TREINO INTELIGENTE';

  @override
  String get settingsAdaptiveBody =>
      'Os graus a que respondes devagar ou erras aparecem muito mais vezes do que os que dominas — certo mas lento ainda conta como não aprendido. O relógio aperta quando estás afiado e alivia quando começas a falhar.';

  @override
  String get settingsAdaptiveLocked =>
      'Função PRO — passa a Pro para desbloquear o treino inteligente que se adapta aos teus pontos fracos.';

  @override
  String get settingsSimpleNotes => 'Nomes simples das notas';

  @override
  String get settingsSimpleNotesTag => 'GRAFIA DAS NOTAS';

  @override
  String get settingsSimpleNotesBody =>
      'Um só nome por nota em todo o lado — sem barras, sem nomes duplos. Dó  Ré♭  Ré  Mi♭  Mi  Fá  Fá♯  Sol  Lá♭  Lá  Si♭  Si.';

  @override
  String get settingsKeyboardTonic => 'Teclado a partir da tónica';

  @override
  String get settingsKeyboardTonicTag => 'ENTRADA DE PIANO';

  @override
  String get settingsKeyboardTonicBody =>
      'O piano do jogo começa na tónica da tua tonalidade em vez de Dó.';

  @override
  String get settingsNotation => 'SISTEMA DE NOTAÇÃO';

  @override
  String get settingsFreeMode => 'MODO LIVRE';

  @override
  String get settingsFreeModeTitle => 'Modo livre';

  @override
  String get settingsFreeModeSub =>
      'Números ao teu ritmo. Sem relógio, sem pontuação.';

  @override
  String get settingsNotifications => 'NOTIFICAÇÕES';

  @override
  String get settingsReminders => 'Lembretes diários';

  @override
  String get settingsRemindersTag => 'QUIZ + SALVA-SEQUÊNCIA';

  @override
  String get settingsRemindersBody =>
      'Um quiz rápido por dia, mais um aviso antes de a tua sequência quebrar.';

  @override
  String get settingsNews => 'NOVIDADES';

  @override
  String get settingsWhatsNew => 'Novidades';

  @override
  String get settingsStore => 'LOJA';

  @override
  String get settingsUpgrade => 'PASSAR A PRO';

  @override
  String get settingsRestorePurchases => 'RESTAURAR COMPRAS';

  @override
  String get settingsProRestored => 'PRO restaurado';

  @override
  String get settingsHomeScreen => 'ECRÃ INICIAL';

  @override
  String get settingsWidgets => 'Widgets';

  @override
  String get settingsWidgetsSub => 'Uma pergunta por hora, no teu ecrã inicial';

  @override
  String get settingsSupport => 'APOIO';

  @override
  String get settingsRate => 'Avaliar o Improvy';

  @override
  String get settingsRateSub =>
      'Uma avaliação é como outros músicos o encontram';

  @override
  String get settingsFeedback => 'Enviar feedback';

  @override
  String get settingsFeedbackSub => 'Direto para nós, sem sair da app';

  @override
  String get settingsFeedbackSent => 'Enviado. Lemos todos.';

  @override
  String get settingsContact => 'Contactar o apoio';

  @override
  String settingsWriteTo(String email) {
    return 'Escreve para $email';
  }

  @override
  String get settingsFollow => 'Seguir o programador';

  @override
  String settingsInstagram(String handle) {
    return 'Encontra-nos no Instagram: @$handle';
  }

  @override
  String get settingsLegal => 'LEGAL';

  @override
  String get settingsClearTitle => 'Apagar todos os dados?';

  @override
  String get settingsClearBody =>
      'Isto apaga permanentemente todo o teu progresso e estatísticas.';

  @override
  String get settingsWidgetsTwo => 'DOIS WIDGETS';

  @override
  String get settingsWidgetQuestion => 'Pergunta';

  @override
  String get settingsWidgetQuestionBody =>
      'Um grau da escala à espera de resposta, um novo a cada hora. Toca para ver a resposta.';

  @override
  String get settingsWidgetDaily => 'Desafio diário';

  @override
  String get settingsWidgetDailyBody =>
      'A tonalidade do dia, a tua pontuação depois de jogares, e a tua sequência.';

  @override
  String get settingsWidgetHow => 'COMO ADICIONAR UM';

  @override
  String get settingsWidgetIos1 =>
      'Mantém premido um espaço vazio do ecrã inicial';

  @override
  String get settingsWidgetIos2 => 'Toca no + no canto superior';

  @override
  String get settingsWidgetIos3 => 'Procura Improvy e escolhe um widget';

  @override
  String get settingsWidgetAndroid2 => 'Toca em Widgets';

  @override
  String get settingsWidgetAndroid3 => 'Encontra o Improvy e arrasta um widget';

  @override
  String statsLevel(int n) {
    return 'NÍVEL $n';
  }

  @override
  String get statsOverall => 'DOMÍNIO\nGERAL';

  @override
  String get statsNotes => 'NOTAS';

  @override
  String get statsStreak => 'SEQUÊNCIA';

  @override
  String get statsNothingYet => 'AINDA NADA PARA MOSTRAR';

  @override
  String get statsLast30 => 'ESTATÍSTICAS DOS ÚLTIMOS 30 JOGOS';

  @override
  String get statsSkillMastery => 'Domínio';

  @override
  String get statsLatestGame => 'ÚLTIMO JOGO';

  @override
  String statsGamesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'HÁ $n JOGOS',
      one: 'HÁ 1 JOGO',
    );
    return '$_temp0';
  }

  @override
  String statsNoData(String when) {
    return 'Sem dados • $when';
  }

  @override
  String statsResponseTimeWhen(String when) {
    return 'Tempo de resposta • $when';
  }

  @override
  String get statsResponseTime => 'Tempo de resposta';

  @override
  String get statsLatest => 'ÚLTIMO';

  @override
  String get statsSpeedTitle => 'A tua velocidade vive aqui';

  @override
  String get statsSpeedBody =>
      'Joga uma sessão e vê cada resposta ficar mais rápida.';

  @override
  String get statsDegreeAccuracy => 'Precisão por grau';

  @override
  String get statsPlays => 'JOGADAS';

  @override
  String get statsAccuracy => 'PRECISÃO';

  @override
  String get statsGamesPlayed => 'Jogos jogados';

  @override
  String get statsHeatmap => 'Mapa do teclado';

  @override
  String get statsByNote => 'DESEMPENHO POR NOTA';

  @override
  String get statsSlow => 'LENTO';

  @override
  String get statsFast => 'RÁPIDO';

  @override
  String get statsRank => 'RANK';

  @override
  String get statsFirstRunTitle => 'Joga uma sessão';

  @override
  String get statsFirstRunBody =>
      'Trinta perguntas numa tonalidade e todos os gráficos desta página se preenchem — a tua velocidade, os graus que erras, as notas que te atrasam.';

  @override
  String get kaTitle => 'ANÁLISE DA TONALIDADE';

  @override
  String get kaMastery => 'DOMÍNIO';

  @override
  String get kaAvgResp => 'RESP. MÉDIA';

  @override
  String get kaPerAnswer => 'POR RESPOSTA';

  @override
  String get kaToday => 'HOJE';

  @override
  String get kaAccuracyOverTime => 'Tempo de resposta';

  @override
  String get kaDegreeMastery => 'Domínio dos graus cromáticos';

  @override
  String get kaModeProgress => 'Progresso por modo';

  @override
  String get kaDegreeToNote => 'GRAU › NOTA';

  @override
  String get kaNoteToDegree => 'NOTA › GRAU';

  @override
  String get kaOfWhat => '…OF WHAT?';

  @override
  String get kaConfusions => 'Confusões frequentes';

  @override
  String get kaNoConfusions => 'SEM CONFUSÕES. EXCELENTE!';

  @override
  String get kaNote => 'NOTA';

  @override
  String get kaHarmonizer => 'Harmonizer';

  @override
  String get kaHarmonizerSub => 'Domínio de “…Of What?”';

  @override
  String get dailyTitle => 'DESAFIO DIÁRIO';

  @override
  String get dailyDone => 'DESAFIO FEITO';

  @override
  String get dailyFlawless => 'IMPECÁVEL';

  @override
  String get dailyOutOfTime => 'TEMPO ESGOTADO';

  @override
  String get dailySharp => 'AFIADO';

  @override
  String get dailySolid => 'SÓLIDO';

  @override
  String get dailyWarmingUp => 'A AQUECER';

  @override
  String get dailyTomorrow => 'AMANHÃ, NOVA TONALIDADE';

  @override
  String get dailyCopied => 'Resultado copiado — cola onde quiseres';

  @override
  String dailyNewIn(String when) {
    return 'Novo desafio em $when';
  }

  @override
  String dailyNextIn(String when) {
    return 'Próximo desafio em $when';
  }

  @override
  String get dailyBackHome => 'Voltar ao início';

  @override
  String get dailyTheRun => 'A RONDA';

  @override
  String get dailyStreak => 'SEQUÊNCIA DE DESAFIOS';

  @override
  String get dailyShare => 'Partilha o teu resultado';

  @override
  String get pocketTitle => 'POCKET MODE';

  @override
  String get pocketDegrees => 'GRAUS';

  @override
  String get pocketDelay => 'PAUSA';

  @override
  String get pocketSession => 'SESSÃO';

  @override
  String get pocketListen => 'OUVE';

  @override
  String get pocketYourTurn => 'A TUA VEZ';

  @override
  String get pocketAnswer => 'RESPOSTA';

  @override
  String get pocketReady => 'PRONTO';

  @override
  String get pocketComplete => 'SESSÃO CONCLUÍDA';

  @override
  String get pocketPlaying => 'A TOCAR';

  @override
  String get pocketPaused => 'EM PAUSA';

  @override
  String get pocketScreenOff => 'Continua com o ecrã desligado';

  @override
  String get pocketAudioSession => 'Sessão de áudio';

  @override
  String get feedbackTitle => 'Diz-nos';

  @override
  String get feedbackBody =>
      'Chega diretamente a nós. Sem app de email, sem conta, sem nome a não ser que o escrevas.';

  @override
  String get feedbackHintBug => 'O que aconteceu, e o que estavas a fazer?';

  @override
  String get feedbackHint => 'O que quiseres dizer.';

  @override
  String get feedbackEmail => 'O teu email — só se quiseres resposta';

  @override
  String get feedbackSend => 'ENVIAR';

  @override
  String get feedbackKindBug => 'Algo está avariado';

  @override
  String get feedbackKindIdea => 'Uma ideia';

  @override
  String get feedbackKindOther => 'Outra coisa';

  @override
  String get levelUp => 'Subiste de nível!';

  @override
  String get levelUpYouAreNow => 'Agora és ';

  @override
  String get awesome => 'Boa!';

  @override
  String whatsNewVersionHere(String v) {
    return 'A versão $v\nchegou';
  }

  @override
  String whatsNewVersion(String v) {
    return 'VERSÃO $v';
  }

  @override
  String get continueLabel => 'CONTINUAR';

  @override
  String get fullChangelog => 'Lista completa de alterações';

  @override
  String get quizFromHome => 'DO TEU ECRÃ INICIAL';

  @override
  String get quizTrain => 'Treinar ';

  @override
  String get freeModeTitle => 'MODO LIVRE';

  @override
  String get freeModeTapNext => 'TOCA EM QUALQUER SÍTIO PARA O PRÓXIMO';

  @override
  String get freeModeNumbersDone => 'NÚMEROS FEITOS';

  @override
  String get freeModeSub => 'Sem pontuação, sem relógio — só repetições.';

  @override
  String get freeModeGoAgain => 'OUTRA VEZ';

  @override
  String get remTargetTitle => 'Treino dirigido 🎯';

  @override
  String get remDailyTitle => 'Desafio diário 🏆';

  @override
  String remDailyBody(String key) {
    return 'O desafio de hoje é em $key maior — uma só tentativa, faz com que conte.';
  }

  @override
  String get remQuizTitle => 'Quiz rápido 🎹';

  @override
  String remQuizBody(String degree, String key) {
    return 'Qual é o $degree de $key maior? Toca para verificar.';
  }

  @override
  String remLevelBody(String pct) {
    return 'Faltam-te $pct% para subir de nível. Fechas a diferença?';
  }

  @override
  String get remMaxedBody => 'No máximo — mantém esses reflexos afiados.';

  @override
  String get remGenericTitle => 'Improvy 🎹';

  @override
  String get remGenericBody =>
      'Cada grau, cada tonalidade, no instante. Tens 3 minutos?';

  @override
  String get remEarTitle => 'Treino auditivo 🎧';

  @override
  String get remEarBody =>
      'Lembrar rápido ganha à teoria lenta. Uma sessão rápida?';

  @override
  String get remFallbackBody => 'Hora de praticar?';

  @override
  String get remComeback3 =>
      'Os graus esquecem-se depressa quando paras. As tuas tonalidades sentem a tua falta.';

  @override
  String get remComeback7 =>
      'Uma semana fora — a tua memória instantânea precisa de aquecer. Voltas?';

  @override
  String get remStreakTitle => 'Não quebres a sequência! 🔥';

  @override
  String remStreakBody(int n) {
    return 'A tua sequência de $n dias acaba esta noite — 2 minutos para a manter viva.';
  }

  @override
  String get clear => 'Apagar';

  @override
  String get statsSigNone => 'NENHUMA';

  @override
  String statsSigSharp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n SUSTENIDOS',
      one: '1 SUSTENIDO',
    );
    return '$_temp0';
  }

  @override
  String statsSigFlat(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n BEMÓIS',
      one: '1 BEMOL',
    );
    return '$_temp0';
  }

  @override
  String remConfusion(String a, String b, String key) {
    return 'Continuas a confundir $a e $b em $key maior. 10 perguntas para resolver?';
  }

  @override
  String get freeModeDone => 'FEITOS';

  @override
  String get freeModeLeft => 'RESTAM';

  @override
  String get animalQuote1 => 'Devagar e sempre se ganha!';

  @override
  String get animalQuote2 => 'Progresso constante!';

  @override
  String get animalQuote3 => 'A deslizar com suavidade!';

  @override
  String get animalQuote4 => 'Rápido como uma lebre!';

  @override
  String get animalQuote5 => 'Astuto e veloz!';

  @override
  String get animalQuote6 => 'A galope, com precisão!';

  @override
  String get animalQuote7 => 'A voar alto! Vista apurada!';

  @override
  String get animalQuote8 => 'Imparável! Verdadeiro Maestro!';

  @override
  String get explainerTapKey => 'TOCA NUMA TONALIDADE';

  @override
  String explainerQuestion(String key, String degree) {
    return 'Em $key, que nota é o $degree?';
  }

  @override
  String get explainerRight => 'É isso.';

  @override
  String get explainerWrong => 'Quase — tenta outra vez.';

  @override
  String get explainerAgain => 'Outra';

  @override
  String summaryFamilyMastery(String family, String key) {
    return '$family · $key';
  }

  @override
  String summaryKeyOverall(String key) {
    return '$key no total';
  }

  @override
  String statsTotalGamesChip(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n PARTIDAS',
      one: '1 PARTIDA',
    );
    return '$_temp0';
  }

  @override
  String homeBestOf(int score, int cap) {
    return '$score/$cap MELHOR';
  }

  @override
  String get dailyMajorSuffix => 'maior';

  @override
  String dailyStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String dailyRule(int questions, int seconds) {
    return '$questions perguntas · $seconds segundos';
  }

  @override
  String get dailySubjectKeyOf => 'Tonalidade de ';

  @override
  String get dailySubjectOn => 'Em ';

  @override
  String get wQuestion => 'PERGUNTA';

  @override
  String get wQuestionLong => 'A PERGUNTA DE HOJE';

  @override
  String get wReveal => 'Toca para ver';

  @override
  String get wDaily => 'DESAFIO';

  @override
  String get wDailyLong => 'DESAFIO DIÁRIO';

  @override
  String get wToday => 'hoje';

  @override
  String get wDone => 'Feito';

  @override
  String get wTomorrow => 'O próximo amanhã';

  @override
  String get wLevel => 'O TEU NÍVEL';

  @override
  String get wMastery => 'DOMÍNIO DAS TONALIDADES';

  @override
  String get wStreak => 'SÉRIE';

  @override
  String get wDays => 'dias seguidos';

  @override
  String get wDayStreak => 'dias de série';

  @override
  String get wAtRisk => 'Joga hoje para não a perderes';

  @override
  String get wNeedsWork => 'A MELHORAR';

  @override
  String get wMastered => 'dominada';

  @override
  String get wWeakHint => 'A tua tonalidade mais fraca. Toca para treinar.';

  @override
  String get wWeakEmpty => 'Joga primeiro uma tonalidade';

  @override
  String get wStart => 'COMEÇAR A TREINAR';

  @override
  String get wHandsFree => 'SEM MÃOS';

  @override
  String get wPocketSub => 'Treina com o ecrã desligado';

  @override
  String get wTheory => 'O GRAU DO DIA';

  @override
  String get wOpenApp => 'Abre o Improvy para preencher.';
}
