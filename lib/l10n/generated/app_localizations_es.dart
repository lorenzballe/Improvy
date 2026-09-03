// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Improvy';

  @override
  String get next => 'Siguiente';

  @override
  String get skip => 'Saltar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Hecho';

  @override
  String get close => 'Cerrar';

  @override
  String get gotIt => 'Entendido';

  @override
  String get notNow => 'Ahora no';

  @override
  String get retry => 'REPETIR';

  @override
  String get home => 'INICIO';

  @override
  String get start => 'EMPEZAR';

  @override
  String get startTraining => 'EMPEZAR A ENTRENAR';

  @override
  String get proOnly => 'SOLO PRO';

  @override
  String get free => 'GRATIS';

  @override
  String get modeDiatonic => 'Diatónico';

  @override
  String get modeChromatic => 'Cromático';

  @override
  String get modeCustom => 'Personalizado';

  @override
  String get modeNoteToNumber => 'Nota a Número';

  @override
  String get modeOfWhat => '…¿De qué?';

  @override
  String get modePocket => 'Modo Pocket';

  @override
  String get modeNormal => 'Normal';

  @override
  String get tierApprentice => 'Aprendiz';

  @override
  String get tierVirtuoso => 'Virtuoso';

  @override
  String get tierMaster => 'Maestro';

  @override
  String get onboardingTag => 'Entrenamiento mental';

  @override
  String get onboardingHeadline => 'Cada nota\nes un\nnúmero.';

  @override
  String get onboardingPromise =>
      'Ve al instante el número que hay bajo cualquier nota, en las doce tonalidades — sin contar, sin libro de teoría.';

  @override
  String get onboardingStart => 'Empezar a entrenar';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfService => 'Términos del servicio';

  @override
  String get explainerEyebrow => 'CÓMO FUNCIONA';

  @override
  String explainerStep(int n) {
    return '$n DE 3';
  }

  @override
  String get explainer1Title => 'Cada tecla\ntiene un número.';

  @override
  String get explainer1Body =>
      'Estas son las siete notas de Do mayor. Los músicos las llaman por su número — el grado — porque el número dice qué está haciendo la nota, y funciona igual en todas las tonalidades.';

  @override
  String get explainer2Title => 'Cambia de tonalidad.\nLos números siguen.';

  @override
  String get explainer2Body =>
      'Toca una tonalidad y observa. Las notas cambian, los números no: el 5 siempre es el 5. Aprende los números una vez y tienes las doce tonalidades.';

  @override
  String get explainer3Title => 'Prueba una.';

  @override
  String get explainer3Body =>
      'Ese es todo el juego. Lo bastante rápido, lo bastante a menudo, y deja de ser aritmética para volverse instinto — dos minutos al día bastan.';

  @override
  String get letsGo => 'Vamos';

  @override
  String get summaryTitle => 'SESIÓN COMPLETADA';

  @override
  String get summaryPerfect => 'PUNTUACIÓN PERFECTA';

  @override
  String get summaryPassed => 'NIVEL SUPERADO';

  @override
  String get summaryCompleted => 'COMPLETADA';

  @override
  String get summaryNotYet => 'TODAVÍA NO — SIGUE';

  @override
  String get summaryCorrect => 'ACIERTOS';

  @override
  String get summaryErrors => 'ERRORES';

  @override
  String get summaryTime => 'TIEMPO';

  @override
  String get summaryAccuracy => 'PRECISIÓN %';

  @override
  String get summaryModeMastery => 'DOMINIO DEL MODO';

  @override
  String get summaryNextDifficulty => 'SIGUIENTE DIFICULTAD';

  @override
  String summaryUpsellTitle(String key) {
    return 'Esa era la mitad gratis de $key';
  }

  @override
  String get summaryUpsellBody =>
      'El cromático añade los cinco grados alterados — el resto de la tonalidad.';

  @override
  String get paywallTitle => 'Improvy Pro';

  @override
  String get paywallLifetime => 'Licencia de por vida';

  @override
  String get paywallTagline => 'Cada tonalidad. Cada modo. Para siempre.';

  @override
  String get paywallEvery => 'Cada ';

  @override
  String get paywallForever => 'Para siempre.';

  @override
  String get paywallWhatYouGet => 'Lo que obtienes, de músico a músico';

  @override
  String get paywallCta => 'Desbloquear acceso de por vida';

  @override
  String paywallPrice(String price) {
    return '$price · pago único';
  }

  @override
  String get paywallRestore => 'Restaurar';

  @override
  String get paywallNoPurchase => 'No se encontró ninguna compra anterior';

  @override
  String get featChromatic => 'Modo Cromático';

  @override
  String get featChromaticMeta => 'las 12 tonalidades';

  @override
  String get featNtn => 'Nota a Número';

  @override
  String get featNtnMeta => 'cromático';

  @override
  String get featOfWhat => '…¿De qué?';

  @override
  String get featOfWhatMeta => 'los 15 grados';

  @override
  String get featPocket => 'Modo Pocket';

  @override
  String get featPocketMeta => 'los 12 grados';

  @override
  String get featCustom => 'Modo Personalizado';

  @override
  String get featCustomMeta => 'cualquier grado';

  @override
  String get featAdaptive => 'Dificultad adaptativa';

  @override
  String get featAdaptiveMeta => 'automática';

  @override
  String get featAnalytics => 'Análisis a fondo';

  @override
  String get featAnalyticsMeta => 'por tonalidad';

  @override
  String get storeNotReadyTitle => 'Tienda no disponible';

  @override
  String get storeNotReadyBody =>
      'Ahora mismo no hay ningún producto disponible para comprar. Inténtalo de nuevo en un momento.';

  @override
  String get almostThereTitle => 'Casi listo';

  @override
  String get almostThereBody =>
      'El pago se realizó pero PRO no se activó automáticamente. Toca Restaurar compras en un momento — no se te cobrará dos veces.';

  @override
  String get billingUnavailableTitle => 'Compras no disponibles';

  @override
  String get billingUnavailableBody =>
      'Las compras dentro de la app no están disponibles en este dispositivo.';

  @override
  String get purchaseFailedTitle => 'Compra fallida';

  @override
  String get purchaseFailedBody =>
      'Algo salió mal al contactar con la tienda. Inténtalo de nuevo.';

  @override
  String get notifPromptTitle => 'Que se quede';

  @override
  String get notifPromptBody =>
      'Un quiz rápido al día mantiene cada nota afilada y tu racha viva. Se apaga cuando quieras.';

  @override
  String get notifPromptYes => 'Sí, recuérdamelo';

  @override
  String get homeAllKeys => 'DOMINIO DE TODAS LAS TONALIDADES';

  @override
  String get homeSpecialModes => 'MODOS ESPECIALES';

  @override
  String get homePickUp => 'SIGUE DONDE LO DEJASTE';

  @override
  String get homeTotalSessions => 'SESIONES TOTALES';

  @override
  String get homeAccuracy => 'PRECISIÓN';

  @override
  String get homeTotalProgress => 'PROGRESO TOTAL';

  @override
  String get homeNextMilestone => 'SIGUIENTE HITO';

  @override
  String get homeMaxLevel => '¡NIVEL MÁXIMO!';

  @override
  String homeLevelShort(int n) {
    return 'NIV $n';
  }

  @override
  String homeToNext(String pct, String animal) {
    return '$pct% para $animal';
  }

  @override
  String get homeNtnDesc => 'Dada una nota, identifica su grado numérico.';

  @override
  String get homeOfWhatDesc =>
      'Una nota es un grado dado — di la tónica. Armoniza cualquier melodía.';

  @override
  String get homePocketDesc =>
      'Ejercicio de audio manos libres: una voz pregunta, espera y dice la nota. Funciona con la pantalla apagada.';

  @override
  String get homeCustomDesc =>
      'Elige tonalidad, dirección y los grados concretos que entrenar.';

  @override
  String homeLastSession(String when) {
    return 'ÚLTIMA SESIÓN • $when';
  }

  @override
  String get homeResume => 'Reanudar sesión';

  @override
  String get homeReadyTitle => '¿Listo para empezar?';

  @override
  String get homeReadyBody => 'Elige una tonalidad arriba';

  @override
  String get homeGamesPlayed => 'PARTIDAS JUGADAS';

  @override
  String get homeChooseMode => 'Elige el modo';

  @override
  String get homeChooseModeSub => 'Elige cómo entrenar hoy';

  @override
  String get homeDiatonicDesc => 'Domina las 7 notas de la escala.';

  @override
  String get homeChromaticDesc => 'Ponte a prueba con los 12 semitonos.';

  @override
  String homeLockedTier(String prev) {
    return 'Sigue entrenando en modo $prev para desbloquear esta dificultad.';
  }

  @override
  String get homeYourProgress => 'TU PROGRESO';

  @override
  String get homeKeepTraining => 'SIGUE ASÍ';

  @override
  String get homeHandsFree => 'Audio manos libres';

  @override
  String get homeJustNow => 'Ahora mismo';

  @override
  String homeMinutesAgo(int n) {
    return 'hace $n min';
  }

  @override
  String homeHoursAgo(int n) {
    return 'hace $n h';
  }

  @override
  String homeDaysAgo(int n) {
    return 'hace $n d';
  }

  @override
  String get homeQuote1 =>
      'Todo maestro fue principiante. ¡Visualicemos esas primeras notas!';

  @override
  String get homeQuote2 =>
      'A mitad de camino — tus instintos se afinan. ¡Sigue!';

  @override
  String get homeQuote3 =>
      'El verdadero dominio vive en los detalles. ¡Confía en tu instinto y toca!';

  @override
  String homeKeyTileLabel(String key, int pct) {
    return 'Tonalidad de $key, $pct por ciento';
  }

  @override
  String get setupTrainingSetup => 'CONFIGURAR ENTRENAMIENTO';

  @override
  String get setupHarmonizeSetup => 'CONFIGURAR ARMONIZACIÓN';

  @override
  String get setupPersonalized => 'PRÁCTICA LIBRE · NO CUENTA PARA EL DOMINIO';

  @override
  String get setupHandsFree => 'MANOS LIBRES · AUDIO';

  @override
  String get setupSelectRootKey => 'Elige la tonalidad';

  @override
  String get setupSelectRootKeySub => 'Elige la base de tu entrenamiento.';

  @override
  String get setupSelectNote => 'Elige la nota';

  @override
  String get setupSelectNoteSub =>
      'La nota de la melodía sostenida toda la sesión.';

  @override
  String get setupIntensity => 'Intensidad';

  @override
  String get setupIntensityChromatic =>
      'Domina las 12 notas cromáticas de esta tonalidad.';

  @override
  String get setupIntensityDiatonic =>
      'Céntrate en las 7 notas de la escala mayor.';

  @override
  String get setupDifficulty => 'Dificultad';

  @override
  String get setupDifficultySub =>
      'A más dificultad, menos tiempo para responder.';

  @override
  String get setupMode => 'Modo';

  @override
  String get setupModeNormalSub => 'Di la nota de un grado, en esta tonalidad.';

  @override
  String get setupModeNtnSub => 'Di el grado de una nota, en esta tonalidad.';

  @override
  String get setupModeOfWhatSub =>
      'Una nota sostenida todo el tiempo — di a qué tonalidad pertenece.';

  @override
  String get setupSelectDegrees => 'Elige los grados';

  @override
  String get setupDegreesToAsk => 'Grados a preguntar';

  @override
  String get setupDegreesAll => 'Todos los grados, extensiones incluidas.';

  @override
  String get setupDegreesChord => 'Las cuatro notas del acorde: 1, 3, 5, 7.';

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
  String get setupQuestions => 'Número de preguntas';

  @override
  String get setupQuestionsSub => '¿Cuántas preguntas en esta sesión?';

  @override
  String get setupKeys => 'Tonalidades';

  @override
  String get setupKeysSub => 'Entrena una tonalidad o mezcla las 12.';

  @override
  String get setupShuffleAll => 'Mezclar todas';

  @override
  String get setupOneKey => 'Una tonalidad';

  @override
  String get setupDegrees => 'Grados';

  @override
  String get setupAnswerDelay => 'Pausa antes de la respuesta';

  @override
  String get setupLength => 'Duración';

  @override
  String get setupLengthSub => 'Número de preguntas (∞ = hasta que pares).';

  @override
  String setupTierLocked(String tier) {
    return '$tier está bloqueado';
  }

  @override
  String setupTierLockedBody(int need, String prev, int have) {
    return 'Primero consigue $need aciertos en $prev. Vas por $have.';
  }

  @override
  String setupBest(int best, int cap) {
    return '$best/$cap RÉCORD';
  }

  @override
  String setupKeyCellLabel(String key, int pct) {
    return '$key, $pct por ciento';
  }

  @override
  String get trainerCorrect => 'CORRECTO';

  @override
  String get trainerWrong => 'INCORRECTO';

  @override
  String get trainerCorrectAnswer => 'RESPUESTA CORRECTA';

  @override
  String get trainerNote => 'NOTA';

  @override
  String get trainerKey => 'TONALIDAD';

  @override
  String get trainerDegree => 'GRADO';

  @override
  String get trainerProgress => 'PROGRESO';

  @override
  String get trainerStreak => 'RACHA';

  @override
  String get trainerPianoKeyboard => 'TECLADO';

  @override
  String get trainerExitTitle => '¿Terminar la sesión?';

  @override
  String trainerExitDaily(int done, int total) {
    return 'Un intento al día y el reloj sigue corriendo — si sales ahora, $done/$total será tu puntuación hasta mañana.';
  }

  @override
  String trainerExitEndless(int done) {
    return 'Vas por $done preguntas — al salir, la sesión termina y la puntuación se guarda.';
  }

  @override
  String trainerExitBody(int done, int total) {
    return 'Vas por $done/$total — si sales, la sesión termina aquí.';
  }

  @override
  String get trainerKeepPlaying => 'SEGUIR JUGANDO';

  @override
  String get trainerQuit => 'SALIR';

  @override
  String get paywallLine1 => 'Cada tonalidad.';

  @override
  String get paywallLine2 => 'Cada modo.';

  @override
  String get paywallLine3 => 'Para siempre.';

  @override
  String get paywallRestoring => 'Restaurando…';

  @override
  String get paywallTerms => 'Términos';

  @override
  String get paywallPrivacy => 'Privacidad';

  @override
  String get animalSnail => 'Caracol';

  @override
  String get animalTurtle => 'Tortuga';

  @override
  String get animalPenguin => 'Pingüino';

  @override
  String get animalRabbit => 'Conejo';

  @override
  String get animalFox => 'Zorro';

  @override
  String get animalHorse => 'Caballo';

  @override
  String get animalFalcon => 'Halcón';

  @override
  String get animalCheetah => 'Guepardo';

  @override
  String get homeShuffleHandsFree => 'Mezcladas · manos libres';

  @override
  String homeTierDifficulty(String tier) {
    return 'Dificultad $tier';
  }

  @override
  String get trainerGridView => 'CUADRÍCULA';

  @override
  String get trainerAccuracy => 'PRECISIÓN';

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get settingsAccountStatus => 'ESTADO DE LA CUENTA';

  @override
  String get settingsFreePlan => 'Plan gratuito';

  @override
  String get settingsProPlan => 'Improvy Pro';

  @override
  String get settingsProSub => 'Todos los modos y tonalidades, desbloqueados.';

  @override
  String get settingsFreeSub =>
      'Toca para desbloquear todos los modos y tonalidades.';

  @override
  String get settingsActive => 'ACTIVO';

  @override
  String get settingsTraining => 'ENTRENAMIENTO';

  @override
  String get settingsAdaptive => 'Dificultad adaptativa';

  @override
  String get settingsAdaptiveTag => 'ENTRENAMIENTO INTELIGENTE';

  @override
  String get settingsAdaptiveBody =>
      'Los grados que respondes despacio o fallas aparecen mucho más a menudo que los que dominas — acertar despacio sigue contando como no aprendido. El reloj se aprieta cuando estás fino y se afloja cuando empiezas a fallar.';

  @override
  String get settingsAdaptiveLocked =>
      'Función PRO — pásate a Pro para desbloquear el entrenamiento inteligente que se adapta a tus puntos débiles.';

  @override
  String get settingsSimpleNotes => 'Nombres simples de notas';

  @override
  String get settingsSimpleNotesTag => 'ESCRITURA DE NOTAS';

  @override
  String get settingsSimpleNotesBody =>
      'Un solo nombre por nota en todas partes — sin barras, sin nombres dobles. Do  Re♭  Re  Mi♭  Mi  Fa  Fa♯  Sol  La♭  La  Si♭  Si.';

  @override
  String get settingsKeyboardTonic => 'Teclado desde la tónica';

  @override
  String get settingsKeyboardTonicTag => 'ENTRADA DE PIANO';

  @override
  String get settingsKeyboardTonicBody =>
      'El piano del juego empieza en la tónica de tu tonalidad en lugar de en Do.';

  @override
  String get settingsNotation => 'SISTEMA DE NOTACIÓN';

  @override
  String get settingsFreeMode => 'MODO LIBRE';

  @override
  String get settingsFreeModeTitle => 'Modo libre';

  @override
  String get settingsFreeModeSub =>
      'Números a tu ritmo. Sin reloj, sin puntuación.';

  @override
  String get settingsNotifications => 'NOTIFICACIONES';

  @override
  String get settingsReminders => 'Recordatorios diarios';

  @override
  String get settingsRemindersTag => 'QUIZ + SALVA-RACHAS';

  @override
  String get settingsRemindersBody =>
      'Un quiz rápido al día, más un aviso antes de que se rompa tu racha.';

  @override
  String get settingsNews => 'NOVEDADES';

  @override
  String get settingsWhatsNew => 'Novedades';

  @override
  String get settingsStore => 'TIENDA';

  @override
  String get settingsUpgrade => 'PASAR A PRO';

  @override
  String get settingsRestorePurchases => 'RESTAURAR COMPRAS';

  @override
  String get settingsProRestored => 'PRO restaurado';

  @override
  String get settingsHomeScreen => 'PANTALLA DE INICIO';

  @override
  String get settingsWidgets => 'Widgets';

  @override
  String get settingsWidgetsSub =>
      'Una pregunta cada hora, en tu pantalla de inicio';

  @override
  String get settingsBackup => 'COPIA DE SEGURIDAD';

  @override
  String get settingsExport => 'Exportar progreso';

  @override
  String get settingsExportSub =>
      'Un archivo con cada tonalidad, puntuación y ajuste';

  @override
  String get settingsExportFailed => 'No se pudo iniciar la exportación';

  @override
  String get settingsRestoreFile => 'Restaurar desde archivo';

  @override
  String get settingsRestoreFileSub => 'Sustituye lo que hay en este teléfono';

  @override
  String get settingsRestored => 'Restaurado. Está todo de vuelta.';

  @override
  String get settingsRestoreTitle => '¿Restaurar desde un archivo?';

  @override
  String get settingsRestoreBody =>
      'Todo lo que hay en este teléfono — cada tonalidad, puntuación y ajuste — se sustituye por lo que hay en el archivo. Tu licencia Pro no se ve afectada.';

  @override
  String get settingsChooseFile => 'Elegir archivo';

  @override
  String get settingsSupport => 'SOPORTE';

  @override
  String get settingsRate => 'Valora Improvy';

  @override
  String get settingsRateSub =>
      'Una valoración es cómo otros músicos la encuentran';

  @override
  String get settingsFeedback => 'Enviar comentarios';

  @override
  String get settingsFeedbackSub => 'Directo a nosotros, sin salir de la app';

  @override
  String get settingsFeedbackSent => 'Enviado. Los leemos todos.';

  @override
  String get settingsContact => 'Contactar con soporte';

  @override
  String settingsWriteTo(String email) {
    return 'Escribe a $email';
  }

  @override
  String get settingsFollow => 'Sigue al desarrollador';

  @override
  String settingsInstagram(String handle) {
    return 'Encuéntranos en Instagram: @$handle';
  }

  @override
  String get settingsLegal => 'LEGAL';

  @override
  String get settingsClearTitle => '¿Borrar todos los datos?';

  @override
  String get settingsClearBody =>
      'Eliminará de forma permanente todo tu progreso y estadísticas.';

  @override
  String get settingsWidgetsTwo => 'DOS WIDGETS';

  @override
  String get settingsWidgetQuestion => 'Pregunta';

  @override
  String get settingsWidgetQuestionBody =>
      'Un grado de la escala esperando respuesta, uno nuevo cada hora. Tócalo para ver la respuesta.';

  @override
  String get settingsWidgetDaily => 'Reto diario';

  @override
  String get settingsWidgetDailyBody =>
      'La tonalidad del día, tu puntuación una vez jugado, y tu racha.';

  @override
  String get settingsWidgetHow => 'CÓMO AÑADIR UNO';

  @override
  String get settingsWidgetIos1 =>
      'Mantén pulsado un espacio vacío de la pantalla de inicio';

  @override
  String get settingsWidgetIos2 => 'Toca el + de la esquina superior';

  @override
  String get settingsWidgetIos3 => 'Busca Improvy y elige un widget';

  @override
  String get settingsWidgetAndroid2 => 'Toca Widgets';

  @override
  String get settingsWidgetAndroid3 => 'Busca Improvy y arrastra un widget';

  @override
  String statsLevel(int n) {
    return 'NIVEL $n';
  }

  @override
  String get statsOverall => 'DOMINIO\nGENERAL';

  @override
  String get statsNotes => 'NOTAS';

  @override
  String get statsStreak => 'RACHA';

  @override
  String get statsNothingYet => 'NADA QUE MOSTRAR TODAVÍA';

  @override
  String get statsLast30 => 'ESTADÍSTICAS DE LAS ÚLTIMAS 30 PARTIDAS';

  @override
  String get statsSkillMastery => 'Dominio';

  @override
  String get statsLatestGame => 'ÚLTIMA PARTIDA';

  @override
  String statsGamesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'HACE $n PARTIDAS',
      one: 'HACE 1 PARTIDA',
    );
    return '$_temp0';
  }

  @override
  String statsNoData(String when) {
    return 'Sin datos • $when';
  }

  @override
  String statsResponseTimeWhen(String when) {
    return 'Tiempo de respuesta • $when';
  }

  @override
  String get statsResponseTime => 'Tiempo de respuesta';

  @override
  String get statsLatest => 'ÚLTIMA';

  @override
  String get statsSpeedTitle => 'Tu velocidad vive aquí';

  @override
  String get statsSpeedBody =>
      'Juega una sesión y mira cómo cada respuesta se vuelve más rápida.';

  @override
  String get statsDegreeAccuracy => 'Precisión por grado';

  @override
  String get statsPlays => 'JUGADAS';

  @override
  String get statsAccuracy => 'PRECISIÓN';

  @override
  String get statsGamesPlayed => 'Partidas jugadas';

  @override
  String get statsHeatmap => 'Mapa del teclado';

  @override
  String get statsByNote => 'RENDIMIENTO POR NOTA';

  @override
  String get statsSlow => 'LENTO';

  @override
  String get statsFast => 'RÁPIDO';

  @override
  String get statsRank => 'PUESTO';

  @override
  String get statsFirstRunTitle => 'Juega una sesión';

  @override
  String get statsFirstRunBody =>
      'Treinta preguntas en una tonalidad y cada gráfico de esta página se rellena — tu velocidad, los grados que fallas, las notas que te frenan.';

  @override
  String get kaTitle => 'ANÁLISIS DE TONALIDAD';

  @override
  String get kaMastery => 'DOMINIO';

  @override
  String get kaAvgResp => 'RESP. MEDIA';

  @override
  String get kaPerAnswer => 'POR RESPUESTA';

  @override
  String get kaToday => 'HOY';

  @override
  String get kaAccuracyOverTime => 'Tiempo de respuesta';

  @override
  String get kaDegreeMastery => 'Dominio de grados cromáticos';

  @override
  String get kaModeProgress => 'Progreso por modo';

  @override
  String get kaDegreeToNote => 'GRADO → NOTA';

  @override
  String get kaNoteToDegree => 'NOTA → GRADO';

  @override
  String get kaOfWhat => '…¿DE QUÉ?';

  @override
  String get kaConfusions => 'Confusiones frecuentes';

  @override
  String get kaNoConfusions => 'SIN CONFUSIONES. ¡GENIAL!';

  @override
  String get kaNote => 'NOTA';

  @override
  String get kaHarmonizer => 'Armonizador';

  @override
  String get kaHarmonizerSub => 'Dominio de “…¿De qué?”';

  @override
  String get dailyTitle => 'RETO DIARIO';

  @override
  String get dailyDone => 'RETO HECHO';

  @override
  String get dailyFlawless => 'IMPECABLE';

  @override
  String get dailyOutOfTime => 'SIN TIEMPO';

  @override
  String get dailySharp => 'AFILADO';

  @override
  String get dailySolid => 'SÓLIDO';

  @override
  String get dailyWarmingUp => 'CALENTANDO';

  @override
  String get dailyTomorrow => 'MAÑANA, NUEVA TONALIDAD';

  @override
  String get dailyCopied => 'Resultado copiado — pégalo donde quieras';

  @override
  String dailyNewIn(String when) {
    return 'Nuevo reto en $when';
  }

  @override
  String dailyNextIn(String when) {
    return 'Siguiente reto en $when';
  }

  @override
  String get dailyBackHome => 'Volver al inicio';

  @override
  String get dailyTheRun => 'LA RONDA';

  @override
  String get dailyStreak => 'RACHA DE RETOS';

  @override
  String get dailyShare => 'Comparte tu resultado';

  @override
  String get pocketTitle => 'MODO POCKET';

  @override
  String get pocketDegrees => 'GRADOS';

  @override
  String get pocketDelay => 'PAUSA';

  @override
  String get pocketSession => 'SESIÓN';

  @override
  String get pocketListen => 'ESCUCHA';

  @override
  String get pocketYourTurn => 'TU TURNO';

  @override
  String get pocketAnswer => 'RESPUESTA';

  @override
  String get pocketReady => 'LISTO';

  @override
  String get pocketComplete => 'SESIÓN COMPLETADA';

  @override
  String get pocketPlaying => 'EN MARCHA';

  @override
  String get pocketPaused => 'EN PAUSA';

  @override
  String get pocketScreenOff => 'Sigue sonando con la pantalla apagada';

  @override
  String get pocketAudioSession => 'Sesión de audio';

  @override
  String get feedbackTitle => 'Cuéntanos';

  @override
  String get feedbackBody =>
      'Nos llega directamente. Sin app de correo, sin cuenta, sin nombre a menos que lo escribas.';

  @override
  String get feedbackHintBug => '¿Qué pasó y qué estabas haciendo?';

  @override
  String get feedbackHint => 'Lo que quieras decirnos.';

  @override
  String get feedbackEmail => 'Tu correo — solo si quieres respuesta';

  @override
  String get feedbackSend => 'ENVIAR';

  @override
  String get feedbackKindBug => 'Algo no funciona';

  @override
  String get feedbackKindIdea => 'Una idea';

  @override
  String get feedbackKindOther => 'Otra cosa';

  @override
  String get levelUp => '¡Subes de nivel!';

  @override
  String get levelUpYouAreNow => 'Ahora eres ';

  @override
  String get awesome => '¡Genial!';

  @override
  String whatsNewVersionHere(String v) {
    return 'La versión $v\nya está aquí';
  }

  @override
  String whatsNewVersion(String v) {
    return 'VERSIÓN $v';
  }

  @override
  String get continueLabel => 'CONTINUAR';

  @override
  String get fullChangelog => 'Lista completa de cambios';

  @override
  String get quizFromHome => 'DESDE TU PANTALLA DE INICIO';

  @override
  String get quizTrain => 'Entrenar ';

  @override
  String get freeModeTitle => 'MODO LIBRE';

  @override
  String get freeModeTapNext => 'TOCA EN CUALQUIER SITIO PARA EL SIGUIENTE';

  @override
  String get freeModeNumbersDone => 'NÚMEROS HECHOS';

  @override
  String get freeModeSub => 'Sin puntuación, sin reloj — solo repeticiones.';

  @override
  String get freeModeGoAgain => 'OTRA VEZ';

  @override
  String get remTargetTitle => 'Práctica dirigida 🎯';

  @override
  String get remDailyTitle => 'Reto diario 🏆';

  @override
  String remDailyBody(String key) {
    return 'El reto de hoy es en $key mayor — un solo intento, que cuente.';
  }

  @override
  String get remQuizTitle => 'Quiz rápido 🎹';

  @override
  String remQuizBody(String degree, String key) {
    return '¿Cuál es el $degree de $key mayor? Toca para comprobarlo.';
  }

  @override
  String remLevelBody(String pct) {
    return 'Te falta un $pct% para subir de nivel. ¿Cierras la brecha?';
  }

  @override
  String get remMaxedBody => 'Al máximo — mantén esos reflejos afilados.';

  @override
  String get remGenericTitle => 'Improvy 🎹';

  @override
  String get remGenericBody =>
      'Cada grado, cada tonalidad, al instante. ¿Tienes 3 minutos?';

  @override
  String get remEarTitle => 'Entrenamiento auditivo 🎧';

  @override
  String get remEarBody =>
      'Recordar rápido vence a la teoría lenta. ¿Una sesión rápida?';

  @override
  String get remFallbackBody => '¿Hora de practicar?';

  @override
  String get remComeback3 =>
      'Los grados se olvidan rápido cuando paras. Tus tonalidades te echan de menos.';

  @override
  String get remComeback7 =>
      'Una semana fuera — tu memoria instantánea necesita calentar. ¿Vuelves?';

  @override
  String get remStreakTitle => '¡No rompas tu racha! 🔥';

  @override
  String remStreakBody(int n) {
    return 'Tu racha de $n días termina esta noche — 2 minutos para mantenerla viva.';
  }

  @override
  String get clear => 'Borrar';

  @override
  String get statsSigNone => 'NINGUNA';

  @override
  String statsSigSharp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n SOSTENIDOS',
      one: '1 SOSTENIDO',
    );
    return '$_temp0';
  }

  @override
  String statsSigFlat(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n BEMOLES',
      one: '1 BEMOL',
    );
    return '$_temp0';
  }

  @override
  String remConfusion(String a, String b, String key) {
    return 'Sigues confundiendo $a y $b en $key mayor. ¿10 preguntas para clavarlo?';
  }

  @override
  String get freeModeDone => 'HECHOS';

  @override
  String get freeModeLeft => 'QUEDAN';

  @override
  String get animalQuote1 => '¡Despacio y constante se gana!';

  @override
  String get animalQuote2 => '¡Progreso constante!';

  @override
  String get animalQuote3 => '¡Deslizándote con suavidad!';

  @override
  String get animalQuote4 => '¡Rápido como una liebre!';

  @override
  String get animalQuote5 => '¡Astuto y veloz!';

  @override
  String get animalQuote6 => '¡Galopando con precisión!';

  @override
  String get animalQuote7 => '¡Volando alto! ¡Vista aguda!';

  @override
  String get animalQuote8 => '¡Imparable! ¡Auténtico Maestro!';

  @override
  String get explainerTapKey => 'TOCA UNA TONALIDAD';

  @override
  String explainerQuestion(String key, String degree) {
    return 'En $key, ¿qué nota es el $degree?';
  }

  @override
  String get explainerRight => 'Eso es.';

  @override
  String get explainerWrong => 'Casi — inténtalo otra vez.';

  @override
  String get explainerAgain => 'Otra';

  @override
  String summaryFamilyMastery(String family, String key) {
    return '$family · $key';
  }

  @override
  String summaryKeyOverall(String key) {
    return '$key en total';
  }
}
