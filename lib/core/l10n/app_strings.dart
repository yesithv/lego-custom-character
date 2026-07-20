// Tabla de traducciones de la app (Run For Win).
//
// Estructura: `clave -> { código-idioma -> texto }`. El español ('es') es la
// fuente de verdad y el idioma de reserva: si falta una traducción, se usa el
// texto en español; si tampoco existe, se devuelve la propia clave.
//
// Escrita a mano (sin generadores), en línea con el resto del proyecto.
// Idiomas soportados: es, en, pt, de, ru, fr.

/// Idiomas soportados por la app, en orden de preferencia. El primero ('es')
/// es el idioma por defecto/reserva.
const List<String> kSupportedLanguages = ['es', 'en', 'pt', 'de', 'ru', 'fr'];

/// Idioma por defecto cuando el dispositivo usa uno no soportado.
const String kFallbackLanguage = 'es';

const Map<String, Map<String, String>> kStrings = {
  // ── Acciones / navegación comunes ─────────────────────────────────────────
  'action_play': {
    'es': '¡JUGAR!', 'en': 'PLAY!', 'pt': 'JOGAR!',
    'de': 'SPIELEN!', 'ru': 'ИГРАТЬ!', 'fr': 'JOUER !',
  },
  'action_run': {
    'es': '¡CORRER!', 'en': 'RUN!', 'pt': 'CORRER!',
    'de': 'LOS!', 'ru': 'БЕГОМ!', 'fr': 'COURIR !',
  },
  'play_again': {
    'es': 'Jugar de nuevo', 'en': 'Play again', 'pt': 'Jogar de novo',
    'de': 'Nochmal spielen', 'ru': 'Играть снова', 'fr': 'Rejouer',
  },
  'choose_world': {
    'es': 'Elegir mundo', 'en': 'Choose world', 'pt': 'Escolher mundo',
    'de': 'Welt wählen', 'ru': 'Выбрать мир', 'fr': 'Choisir un monde',
  },
  'exit_to_map': {
    'es': 'Salir al mapa', 'en': 'Exit to map', 'pt': 'Sair para o mapa',
    'de': 'Zur Karte', 'ru': 'Выйти на карту', 'fr': 'Retour à la carte',
  },
  'resume': {
    'es': 'Continuar', 'en': 'Continue', 'pt': 'Continuar',
    'de': 'Weiter', 'ru': 'Продолжить', 'fr': 'Continuer',
  },
  'cancel': {
    'es': 'Cancelar', 'en': 'Cancel', 'pt': 'Cancelar',
    'de': 'Abbrechen', 'ru': 'Отмена', 'fr': 'Annuler',
  },
  'ok_understood': {
    'es': 'Entendido', 'en': 'Got it', 'pt': 'Entendi',
    'de': 'Verstanden', 'ru': 'Понятно', 'fr': 'Compris',
  },
  'delete': {
    'es': 'Eliminar', 'en': 'Delete', 'pt': 'Excluir',
    'de': 'Löschen', 'ru': 'Удалить', 'fr': 'Supprimer',
  },
  'edit': {
    'es': 'Editar', 'en': 'Edit', 'pt': 'Editar',
    'de': 'Bearbeiten', 'ru': 'Изменить', 'fr': 'Modifier',
  },
  'create_character': {
    'es': 'Crear personaje', 'en': 'Create character', 'pt': 'Criar personagem',
    'de': 'Figur erstellen', 'ru': 'Создать персонажа', 'fr': 'Créer un personnage',
  },
  'my_characters': {
    'es': 'Mis personajes', 'en': 'My characters', 'pt': 'Meus personagens',
    'de': 'Meine Figuren', 'ru': 'Мои персонажи', 'fr': 'Mes personnages',
  },
  'view_ranking': {
    'es': 'Ver Ranking', 'en': 'View Ranking', 'pt': 'Ver Ranking',
    'de': 'Rangliste', 'ru': 'Рейтинг', 'fr': 'Classement',
  },
  'view_ranking_short': {
    'es': 'Ver ranking', 'en': 'View ranking', 'pt': 'Ver ranking',
    'de': 'Rangliste ansehen', 'ru': 'Смотреть рейтинг', 'fr': 'Voir le classement',
  },
  'no_name': {
    'es': 'Sin nombre', 'en': 'No name', 'pt': 'Sem nome',
    'de': 'Kein Name', 'ru': 'Без имени', 'fr': 'Sans nom',
  },
  'play': {
    'es': 'Jugar', 'en': 'Play', 'pt': 'Jogar',
    'de': 'Spielen', 'ru': 'Играть', 'fr': 'Jouer',
  },
  'new_label': {
    'es': 'Nuevo', 'en': 'New', 'pt': 'Novo',
    'de': 'Neu', 'ru': 'Новый', 'fr': 'Nouveau',
  },
  'copy_suffix': {
    'es': '(copia)', 'en': '(copy)', 'pt': '(cópia)',
    'de': '(Kopie)', 'ru': '(копия)', 'fr': '(copie)',
  },

  // ── Home ──────────────────────────────────────────────────────────────────
  'home_test_banner': {
    'es': 'MODO PRUEBA ACTIVO · todo desbloqueado',
    'en': 'TEST MODE ON · everything unlocked',
    'pt': 'MODO TESTE ATIVO · tudo desbloqueado',
    'de': 'TESTMODUS AKTIV · alles freigeschaltet',
    'ru': 'ТЕСТ-РЕЖИМ ВКЛ · всё открыто',
    'fr': 'MODE TEST ACTIF · tout débloqué',
  },
  'home_perk_roulette': {
    'es': 'Ruleta diaria siempre disponible',
    'en': 'Daily wheel always available',
    'pt': 'Roleta diária sempre disponível',
    'de': 'Tägliches Glücksrad immer verfügbar',
    'ru': 'Ежедневная рулетка всегда доступна',
    'fr': 'Roue quotidienne toujours disponible',
  },
  'home_perk_accessories': {
    'es': 'Todos los accesorios de pago, gratis',
    'en': 'All paid accessories, free',
    'pt': 'Todos os acessórios pagos, grátis',
    'de': 'Alle kostenpflichtigen Extras, gratis',
    'ru': 'Все платные аксессуары бесплатно',
    'fr': 'Tous les accessoires payants, gratuits',
  },
  'home_perk_worlds': {
    'es': 'Todos los mundos y pistas desbloqueados',
    'en': 'All worlds and tracks unlocked',
    'pt': 'Todos os mundos e pistas desbloqueados',
    'de': 'Alle Welten und Strecken freigeschaltet',
    'ru': 'Все миры и трассы открыты',
    'fr': 'Tous les mondes et pistes débloqués',
  },
  'home_perk_short_track': {
    'es': 'Pista súper corta: el jefe aparece enseguida',
    'en': 'Super short track: the boss appears right away',
    'pt': 'Pista supercurta: o chefe aparece logo',
    'de': 'Sehr kurze Strecke: der Boss kommt sofort',
    'ru': 'Очень короткая трасса: босс появляется сразу',
    'fr': 'Piste très courte : le boss arrive tout de suite',
  },
  'home_perk_weak_boss': {
    'es': 'Jefe muy débil: derrótalo de un golpe',
    'en': 'Very weak boss: beat it in one hit',
    'pt': 'Chefe muito fraco: derrote-o num golpe',
    'de': 'Sehr schwacher Boss: mit einem Schlag besiegt',
    'ru': 'Очень слабый босс: победи одним ударом',
    'fr': 'Boss très faible : battez-le en un coup',
  },
  'test_mode': {
    'es': 'Modo de prueba', 'en': 'Test mode', 'pt': 'Modo de teste',
    'de': 'Testmodus', 'ru': 'Тестовый режим', 'fr': 'Mode test',
  },
  'test_mode_on_desc': {
    'es': 'Encendido: se ignoran todas las limitaciones del juego.',
    'en': 'On: all game limits are ignored.',
    'pt': 'Ligado: todas as limitações do jogo são ignoradas.',
    'de': 'An: alle Spielgrenzen werden ignoriert.',
    'ru': 'Включено: все ограничения игры игнорируются.',
    'fr': 'Activé : toutes les limites du jeu sont ignorées.',
  },
  'test_mode_off_desc': {
    'es': 'Apagado: el juego funciona con sus reglas normales.',
    'en': 'Off: the game runs with its normal rules.',
    'pt': 'Desligado: o jogo funciona com as regras normais.',
    'de': 'Aus: das Spiel läuft mit den normalen Regeln.',
    'ru': 'Выключено: игра работает по обычным правилам.',
    'fr': 'Désactivé : le jeu suit ses règles normales.',
  },
  'test_mode_footer': {
    'es': 'Los cambios de pista y jefe se aplican en la próxima carrera.',
    'en': 'Track and boss changes apply on the next run.',
    'pt': 'As mudanças de pista e chefe valem na próxima corrida.',
    'de': 'Strecken- und Boss-Änderungen gelten ab dem nächsten Lauf.',
    'ru': 'Изменения трассы и босса применятся в следующем забеге.',
    'fr': 'Les changements de piste et de boss s’appliquent à la prochaine course.',
  },
  'view_analytics_panel': {
    'es': 'Ver panel de analítica', 'en': 'Open analytics panel',
    'pt': 'Ver painel de análise', 'de': 'Analyse-Panel öffnen',
    'ru': 'Открыть панель аналитики', 'fr': 'Voir le panneau d’analyse',
  },
  'home_create_runner': {
    'es': 'Crea tu corredor', 'en': 'Create your runner', 'pt': 'Crie seu corredor',
    'de': 'Erstelle deinen Läufer', 'ru': 'Создай бегуна', 'fr': 'Crée ton coureur',
  },
  'home_need_char_run': {
    'es': 'Necesitas un personaje para correr',
    'en': 'You need a character to run',
    'pt': 'Você precisa de um personagem para correr',
    'de': 'Du brauchst eine Figur zum Laufen',
    'ru': 'Нужен персонаж, чтобы бежать',
    'fr': 'Il te faut un personnage pour courir',
  },

  // ── Tipos de personaje ────────────────────────────────────────────────────
  'type_hero': {
    'es': 'Héroe', 'en': 'Hero', 'pt': 'Herói',
    'de': 'Held', 'ru': 'Герой', 'fr': 'Héros',
  },
  'type_villain': {
    'es': 'Villano', 'en': 'Villain', 'pt': 'Vilão',
    'de': 'Schurke', 'ru': 'Злодей', 'fr': 'Méchant',
  },
  'type_neutral': {
    'es': 'Neutral', 'en': 'Neutral', 'pt': 'Neutro',
    'de': 'Neutral', 'ru': 'Нейтральный', 'fr': 'Neutre',
  },
  'type_mysterious': {
    'es': 'Misterioso', 'en': 'Mysterious', 'pt': 'Misterioso',
    'de': 'Geheimnisvoll', 'ru': 'Загадочный', 'fr': 'Mystérieux',
  },

  // ── Rareza ────────────────────────────────────────────────────────────────
  'rarity_common': {
    'es': 'Común', 'en': 'Common', 'pt': 'Comum',
    'de': 'Gewöhnlich', 'ru': 'Обычный', 'fr': 'Commun',
  },
  'rarity_rare': {
    'es': 'Raro', 'en': 'Rare', 'pt': 'Raro',
    'de': 'Selten', 'ru': 'Редкий', 'fr': 'Rare',
  },
  'rarity_epic': {
    'es': 'Épico', 'en': 'Epic', 'pt': 'Épico',
    'de': 'Episch', 'ru': 'Эпический', 'fr': 'Épique',
  },
  'rarity_legendary': {
    'es': 'Legendario', 'en': 'Legendary', 'pt': 'Lendário',
    'de': 'Legendär', 'ru': 'Легендарный', 'fr': 'Légendaire',
  },
  // Variantes del cofre (mayúsculas/exclamación).
  'chest_common': {
    'es': 'Común', 'en': 'Common', 'pt': 'Comum',
    'de': 'Gewöhnlich', 'ru': 'Обычный', 'fr': 'Commun',
  },
  'chest_rare': {
    'es': '¡Raro!', 'en': 'Rare!', 'pt': 'Raro!',
    'de': 'Selten!', 'ru': 'Редкий!', 'fr': 'Rare !',
  },
  'chest_epic': {
    'es': '¡Épico!', 'en': 'Epic!', 'pt': 'Épico!',
    'de': 'Episch!', 'ru': 'Эпический!', 'fr': 'Épique !',
  },
  'chest_legendary': {
    'es': '¡LEGENDARIO!', 'en': 'LEGENDARY!', 'pt': 'LENDÁRIO!',
    'de': 'LEGENDÄR!', 'ru': 'ЛЕГЕНДАРНЫЙ!', 'fr': 'LÉGENDAIRE !',
  },
  'chest_coins': {
    'es': 'Monedas', 'en': 'Coins', 'pt': 'Moedas',
    'de': 'Münzen', 'ru': 'Монеты', 'fr': 'Pièces',
  },

  // ── Selección de mundo ────────────────────────────────────────────────────
  'choose_your_world': {
    'es': 'Elige tu mundo', 'en': 'Choose your world', 'pt': 'Escolha seu mundo',
    'de': 'Wähle deine Welt', 'ru': 'Выбери свой мир', 'fr': 'Choisis ton monde',
  },
  'need_char_play': {
    'es': 'Necesitas un personaje para jugar',
    'en': 'You need a character to play',
    'pt': 'Você precisa de um personagem para jogar',
    'de': 'Du brauchst eine Figur zum Spielen',
    'ru': 'Нужен персонаж, чтобы играть',
    'fr': 'Il te faut un personnage pour jouer',
  },
  'runner_label': {
    'es': 'CORREDOR', 'en': 'RUNNER', 'pt': 'CORREDOR',
    'de': 'LÄUFER', 'ru': 'БЕГУН', 'fr': 'COUREUR',
  },
  'world_locked_snack': {
    'es': 'Llevas 🪙 {earned} de {cost}. ¡Te faltan {remaining} para desbloquear {name}!',
    'en': 'You have 🪙 {earned} of {cost}. {remaining} more to unlock {name}!',
    'pt': 'Você tem 🪙 {earned} de {cost}. Faltam {remaining} para desbloquear {name}!',
    'de': 'Du hast 🪙 {earned} von {cost}. Noch {remaining} bis {name} frei ist!',
    'ru': 'У тебя 🪙 {earned} из {cost}. Ещё {remaining}, чтобы открыть {name}!',
    'fr': 'Tu as 🪙 {earned} sur {cost}. Encore {remaining} pour débloquer {name} !',
  },
  // Etiquetas de zona en las tarjetas de mundo.
  'tag_start': {
    'es': 'Inicio', 'en': 'Start', 'pt': 'Início',
    'de': 'Start', 'ru': 'Старт', 'fr': 'Début',
  },
  'tag_core': {
    'es': 'Núcleo', 'en': 'Core', 'pt': 'Núcleo',
    'de': 'Kern', 'ru': 'Ядро', 'fr': 'Cœur',
  },
  'tag_chaos': {
    'es': 'Caos', 'en': 'Chaos', 'pt': 'Caos',
    'de': 'Chaos', 'ru': 'Хаос', 'fr': 'Chaos',
  },

  // ── Nombres de mundo ──────────────────────────────────────────────────────
  'world_brix_city_name': {
    'es': 'Ciudad Brix', 'en': 'Brix City', 'pt': 'Cidade Brix',
    'de': 'Brix-Stadt', 'ru': 'Город Брикс', 'fr': 'Ville Brix',
  },
  'world_brix_city_desc': {
    'es': 'Calles de bloques, semáforos y autos.',
    'en': 'Block streets, traffic lights and cars.',
    'pt': 'Ruas de blocos, semáforos e carros.',
    'de': 'Klötzchen-Straßen, Ampeln und Autos.',
    'ru': 'Блочные улицы, светофоры и машины.',
    'fr': 'Rues en briques, feux et voitures.',
  },
  'world_medieval_name': {
    'es': 'Reino Medieval', 'en': 'Medieval Realm', 'pt': 'Reino Medieval',
    'de': 'Mittelalterreich', 'ru': 'Средневековое царство', 'fr': 'Royaume médiéval',
  },
  'world_medieval_desc': {
    'es': 'Castillo, foso y catapultas.',
    'en': 'Castle, moat and catapults.',
    'pt': 'Castelo, fosso e catapultas.',
    'de': 'Burg, Graben und Katapulte.',
    'ru': 'Замок, ров и катапульты.',
    'fr': 'Château, douves et catapultes.',
  },
  'world_galaxy_name': {
    'es': 'Galaxia Brix', 'en': 'Brix Galaxy', 'pt': 'Galáxia Brix',
    'de': 'Brix-Galaxie', 'ru': 'Галактика Брикс', 'fr': 'Galaxie Brix',
  },
  'world_galaxy_desc': {
    'es': 'Estación espacial y asteroides.',
    'en': 'Space station and asteroids.',
    'pt': 'Estação espacial e asteroides.',
    'de': 'Raumstation und Asteroiden.',
    'ru': 'Космическая станция и астероиды.',
    'fr': 'Station spatiale et astéroïdes.',
  },
  'world_jungle_name': {
    'es': 'Jungla Salvaje', 'en': 'Wild Jungle', 'pt': 'Selva Selvagem',
    'de': 'Wilder Dschungel', 'ru': 'Дикие джунгли', 'fr': 'Jungle sauvage',
  },
  'world_jungle_desc': {
    'es': 'Árboles de bloques, ríos y lianas.',
    'en': 'Block trees, rivers and vines.',
    'pt': 'Árvores de blocos, rios e cipós.',
    'de': 'Klötzchen-Bäume, Flüsse und Lianen.',
    'ru': 'Блочные деревья, реки и лианы.',
    'fr': 'Arbres en briques, rivières et lianes.',
  },
  'world_dark_city_name': {
    'es': 'Ciudad Oscura', 'en': 'Dark City', 'pt': 'Cidade Sombria',
    'de': 'Dunkle Stadt', 'ru': 'Тёмный город', 'fr': 'Ville sombre',
  },
  'world_dark_city_desc': {
    'es': 'Halloween, cementerio y niebla.',
    'en': 'Halloween, graveyard and fog.',
    'pt': 'Halloween, cemitério e névoa.',
    'de': 'Halloween, Friedhof und Nebel.',
    'ru': 'Хэллоуин, кладбище и туман.',
    'fr': 'Halloween, cimetière et brouillard.',
  },
  'world_ocean_name': {
    'es': 'Fondo del Mar', 'en': 'Ocean Floor', 'pt': 'Fundo do Mar',
    'de': 'Meeresgrund', 'ru': 'Морское дно', 'fr': 'Fond de la mer',
  },
  'world_ocean_desc': {
    'es': 'Arrecifes de coral y burbujas.',
    'en': 'Coral reefs and bubbles.',
    'pt': 'Recifes de coral e bolhas.',
    'de': 'Korallenriffe und Blasen.',
    'ru': 'Коралловые рифы и пузырьки.',
    'fr': 'Récifs coralliens et bulles.',
  },
  'world_tundra_name': {
    'es': 'Tundra Helada', 'en': 'Frozen Tundra', 'pt': 'Tundra Gelada',
    'de': 'Eisige Tundra', 'ru': 'Ледяная тундра', 'fr': 'Toundra gelée',
  },
  'world_tundra_desc': {
    'es': 'Nieve, témpanos y ventisca.',
    'en': 'Snow, ice floes and blizzard.',
    'pt': 'Neve, icebergs e nevasca.',
    'de': 'Schnee, Eisschollen und Schneesturm.',
    'ru': 'Снег, льдины и метель.',
    'fr': 'Neige, banquises et blizzard.',
  },
  'world_robot_city_name': {
    'es': 'Metrópolis Robot', 'en': 'Robot Metropolis', 'pt': 'Metrópole Robô',
    'de': 'Roboter-Metropole', 'ru': 'Роботополис', 'fr': 'Métropole Robot',
  },
  'world_robot_city_desc': {
    'es': 'Fábricas, engranajes y pantallas.',
    'en': 'Factories, gears and screens.',
    'pt': 'Fábricas, engrenagens e telas.',
    'de': 'Fabriken, Zahnräder und Bildschirme.',
    'ru': 'Заводы, шестерни и экраны.',
    'fr': 'Usines, engrenages et écrans.',
  },

  // ── Nombres de jefe ───────────────────────────────────────────────────────
  'boss_brix_city': {
    'es': 'Capataz Demoledor', 'en': 'Demolition Foreman', 'pt': 'Capataz Demolidor',
    'de': 'Abriss-Vorarbeiter', 'ru': 'Прораб-Разрушитель', 'fr': 'Chef démolisseur',
  },
  'boss_medieval': {
    'es': 'Dragón Oscuro', 'en': 'Dark Dragon', 'pt': 'Dragão Sombrio',
    'de': 'Dunkler Drache', 'ru': 'Тёмный дракон', 'fr': 'Dragon sombre',
  },
  'boss_galaxy': {
    'es': 'Overlord Zenth', 'en': 'Overlord Zenth', 'pt': 'Overlord Zenth',
    'de': 'Overlord Zenth', 'ru': 'Оверлорд Зент', 'fr': 'Overlord Zenth',
  },
  'boss_jungle': {
    'es': 'Gran Gorila', 'en': 'Great Gorilla', 'pt': 'Grande Gorila',
    'de': 'Großer Gorilla', 'ru': 'Большая горилла', 'fr': 'Grand Gorille',
  },
  'boss_dark_city': {
    'es': 'Señor Sombra', 'en': 'Lord Shadow', 'pt': 'Senhor Sombra',
    'de': 'Herr Schatten', 'ru': 'Владыка Тьмы', 'fr': 'Seigneur Ombre',
  },
  'boss_ocean': {
    'es': 'Kraken Abisal', 'en': 'Abyssal Kraken', 'pt': 'Kraken Abissal',
    'de': 'Abgrund-Krake', 'ru': 'Бездонный Кракен', 'fr': 'Kraken abyssal',
  },
  'boss_tundra': {
    'es': 'Yeti Glacial', 'en': 'Glacial Yeti', 'pt': 'Yeti Glacial',
    'de': 'Gletscher-Yeti', 'ru': 'Ледяной Йети', 'fr': 'Yéti glaciaire',
  },
  'boss_robot_city': {
    'es': 'Mega-Bot X9', 'en': 'Mega-Bot X9', 'pt': 'Mega-Bot X9',
    'de': 'Mega-Bot X9', 'ru': 'Мега-Бот X9', 'fr': 'Méga-Bot X9',
  },

  // ── Ranking ───────────────────────────────────────────────────────────────
  'ranking': {
    'es': 'Ranking', 'en': 'Ranking', 'pt': 'Ranking',
    'de': 'Rangliste', 'ru': 'Рейтинг', 'fr': 'Classement',
  },
  'world_label': {
    'es': 'MUNDO', 'en': 'WORLD', 'pt': 'MUNDO',
    'de': 'WELT', 'ru': 'МИР', 'fr': 'MONDE',
  },
  'period_week': {
    'es': 'Semana', 'en': 'Week', 'pt': 'Semana',
    'de': 'Woche', 'ru': 'Неделя', 'fr': 'Semaine',
  },
  'period_month': {
    'es': 'Mes', 'en': 'Month', 'pt': 'Mês',
    'de': 'Monat', 'ru': 'Месяц', 'fr': 'Mois',
  },
  'period_global': {
    'es': 'Global', 'en': 'All time', 'pt': 'Global',
    'de': 'Gesamt', 'ru': 'За всё время', 'fr': 'Global',
  },
  'you': {
    'es': 'Tú', 'en': 'You', 'pt': 'Você',
    'de': 'Du', 'ru': 'Ты', 'fr': 'Toi',
  },
  'default_runner': {
    'es': 'Corredor', 'en': 'Runner', 'pt': 'Corredor',
    'de': 'Läufer', 'ru': 'Бегун', 'fr': 'Coureur',
  },
  'ranking_empty_global': {
    'es': '¡Sé el primero en correr aquí!',
    'en': 'Be the first to run here!',
    'pt': 'Seja o primeiro a correr aqui!',
    'de': 'Sei der Erste, der hier läuft!',
    'ru': 'Стань первым, кто пробежит здесь!',
    'fr': 'Sois le premier à courir ici !',
  },
  'ranking_empty_period': {
    'es': 'Sin marcas en este periodo',
    'en': 'No scores in this period',
    'pt': 'Sem marcas neste período',
    'de': 'Keine Ergebnisse in diesem Zeitraum',
    'ru': 'Нет результатов за этот период',
    'fr': 'Aucun score sur cette période',
  },
  'ranking_empty_hint': {
    'es': 'Corre en este mundo para entrar al ranking.',
    'en': 'Run in this world to join the ranking.',
    'pt': 'Corra neste mundo para entrar no ranking.',
    'de': 'Laufe in dieser Welt, um in die Rangliste zu kommen.',
    'ru': 'Пробеги в этом мире, чтобы попасть в рейтинг.',
    'fr': 'Cours dans ce monde pour entrer au classement.',
  },

  // ── Runner (HUD, pausa, fin de partida, victoria) ─────────────────────────
  'dash_hint': {
    'es': 'Esquiva ataques para cargar tu EMBESTIDA',
    'en': 'Dodge attacks to charge your DASH',
    'pt': 'Desvie de ataques para carregar seu AVANÇO',
    'de': 'Weiche Angriffen aus, um deinen ANSTURM zu laden',
    'ru': 'Уворачивайся от атак, чтобы зарядить РЫВОК',
    'fr': 'Esquive les attaques pour charger ta CHARGE',
  },
  'boss_approaching': {
    'es': '¡{name} se acerca!', 'en': '{name} is coming!',
    'pt': '{name} está chegando!', 'de': '{name} kommt!',
    'ru': '{name} приближается!', 'fr': '{name} approche !',
  },
  'boss_intro': {
    'es': '¡{name}!', 'en': '{name}!', 'pt': '{name}!',
    'de': '{name}!', 'ru': '{name}!', 'fr': '{name} !',
  },
  'dash_ready': {
    'es': '¡EMBESTIDA!', 'en': 'DASH!', 'pt': 'AVANÇO!',
    'de': 'ANSTURM!', 'ru': 'РЫВОК!', 'fr': 'CHARGE !',
  },
  'defeated': {
    'es': '¡DERROTADO!', 'en': 'DEFEATED!', 'pt': 'DERROTADO!',
    'de': 'BESIEGT!', 'ru': 'ПОБЕЖДЁН!', 'fr': 'VAINCU !',
  },
  'combo': {
    'es': 'combo', 'en': 'combo', 'pt': 'combo',
    'de': 'Combo', 'ru': 'комбо', 'fr': 'combo',
  },
  'zone_start': {
    'es': 'Zona Inicio', 'en': 'Start Zone', 'pt': 'Zona Início',
    'de': 'Startzone', 'ru': 'Зона старта', 'fr': 'Zone Départ',
  },
  'zone_core': {
    'es': 'Zona Núcleo', 'en': 'Core Zone', 'pt': 'Zona Núcleo',
    'de': 'Kernzone', 'ru': 'Зона ядра', 'fr': 'Zone Cœur',
  },
  'zone_chaos': {
    'es': 'Zona Caos', 'en': 'Chaos Zone', 'pt': 'Zona Caos',
    'de': 'Chaoszone', 'ru': 'Зона хаоса', 'fr': 'Zone Chaos',
  },
  'pause': {
    'es': 'Pausa', 'en': 'Pause', 'pt': 'Pausa',
    'de': 'Pause', 'ru': 'Пауза', 'fr': 'Pause',
  },
  'keep_creating': {
    'es': '¡Sigue creando!', 'en': 'Keep creating!', 'pt': 'Continue criando!',
    'de': 'Weiter erschaffen!', 'ru': 'Твори дальше!', 'fr': 'Continue de créer !',
  },
  'almost_podium': {
    'es': '¡Casi llegas al podio!', 'en': 'Almost on the podium!',
    'pt': 'Quase no pódio!', 'de': 'Fast auf dem Podest!',
    'ru': 'Почти на пьедестале!', 'fr': 'Presque sur le podium !',
  },
  'stat_meters': {
    'es': 'metros', 'en': 'meters', 'pt': 'metros',
    'de': 'Meter', 'ru': 'метры', 'fr': 'mètres',
  },
  'stat_coins': {
    'es': 'monedas', 'en': 'coins', 'pt': 'moedas',
    'de': 'Münzen', 'ru': 'монеты', 'fr': 'pièces',
  },
  'stat_points': {
    'es': 'puntos', 'en': 'points', 'pt': 'pontos',
    'de': 'Punkte', 'ru': 'очки', 'fr': 'points',
  },
  'new_record': {
    'es': '¡Nuevo récord!', 'en': 'New record!', 'pt': 'Novo recorde!',
    'de': 'Neuer Rekord!', 'ru': 'Новый рекорд!', 'fr': 'Nouveau record !',
  },
  'record_pts': {
    'es': 'Récord: {pb} pts', 'en': 'Record: {pb} pts',
    'pt': 'Recorde: {pb} pts', 'de': 'Rekord: {pb} Pkt',
    'ru': 'Рекорд: {pb} очк.', 'fr': 'Record : {pb} pts',
  },
  'missions_completed': {
    'es': 'Misiones completadas', 'en': 'Completed missions',
    'pt': 'Missões concluídas', 'de': 'Abgeschlossene Missionen',
    'ru': 'Выполненные миссии', 'fr': 'Missions accomplies',
  },
  'victory': {
    'es': '¡VICTORIA!', 'en': 'VICTORY!', 'pt': 'VITÓRIA!',
    'de': 'SIEG!', 'ru': 'ПОБЕДА!', 'fr': 'VICTOIRE !',
  },
  'world_completed': {
    'es': '{emoji}  {name} completada',
    'en': '{emoji}  {name} completed',
    'pt': '{emoji}  {name} concluído',
    'de': '{emoji}  {name} geschafft',
    'ru': '{emoji}  {name} пройден',
    'fr': '{emoji}  {name} terminé',
  },
  'claim_chest': {
    'es': 'Reclamar cofre', 'en': 'Claim chest', 'pt': 'Resgatar baú',
    'de': 'Truhe abholen', 'ru': 'Забрать сундук', 'fr': 'Réclamer le coffre',
  },

  // ── Pre-run ───────────────────────────────────────────────────────────────
  'missions_active': {
    'es': 'Misiones activas', 'en': 'Active missions', 'pt': 'Missões ativas',
    'de': 'Aktive Missionen', 'ru': 'Активные миссии', 'fr': 'Missions actives',
  },
  'no_active_missions': {
    'es': 'Sin misiones activas por ahora.',
    'en': 'No active missions for now.',
    'pt': 'Nenhuma missão ativa por enquanto.',
    'de': 'Momentan keine aktiven Missionen.',
    'ru': 'Пока нет активных миссий.',
    'fr': 'Aucune mission active pour le moment.',
  },
  'world_music': {
    'es': 'Música del mundo', 'en': 'World music', 'pt': 'Música do mundo',
    'de': 'Weltmusik', 'ru': 'Музыка мира', 'fr': 'Musique du monde',
  },
  'music_off_hint': {
    'es': 'Correrás en silencio. Activa el interruptor para elegir una pista.',
    'en': 'You’ll run in silence. Flip the switch to pick a track.',
    'pt': 'Você correrá em silêncio. Ligue o botão para escolher uma faixa.',
    'de': 'Du läufst in Stille. Schalte um, um einen Titel zu wählen.',
    'ru': 'Ты побежишь в тишине. Включи переключатель, чтобы выбрать трек.',
    'fr': 'Tu courras en silence. Active l’interrupteur pour choisir une piste.',
  },

  // ── Galería de personajes ─────────────────────────────────────────────────
  'delete_character': {
    'es': 'Eliminar personaje', 'en': 'Delete character', 'pt': 'Excluir personagem',
    'de': 'Figur löschen', 'ru': 'Удалить персонажа', 'fr': 'Supprimer le personnage',
  },
  'delete_character_confirm': {
    'es': '¿Seguro que quieres eliminar {name}? Esta acción no se puede deshacer.',
    'en': 'Are you sure you want to delete {name}? This can’t be undone.',
    'pt': 'Tem certeza de que deseja excluir {name}? Isso não pode ser desfeito.',
    'de': 'Möchtest du {name} wirklich löschen? Das kann nicht rückgängig gemacht werden.',
    'ru': 'Точно удалить {name}? Это действие нельзя отменить.',
    'fr': 'Voulez-vous vraiment supprimer {name} ? Action irréversible.',
  },
  'this_character': {
    'es': 'este personaje', 'en': 'this character', 'pt': 'este personagem',
    'de': 'diese Figur', 'ru': 'этого персонажа', 'fr': 'ce personnage',
  },
  'view_presets': {
    'es': 'Ver personajes precargados', 'en': 'View preset characters',
    'pt': 'Ver personagens prontos', 'de': 'Vorlagen ansehen',
    'ru': 'Смотреть готовых персонажей', 'fr': 'Voir les personnages prédéfinis',
  },
  'create_first_character': {
    'es': '¡Crea tu primer personaje!', 'en': 'Create your first character!',
    'pt': 'Crie seu primeiro personagem!', 'de': 'Erstelle deine erste Figur!',
    'ru': 'Создай своего первого персонажа!', 'fr': 'Crée ton premier personnage !',
  },
  'design_minifig_hint': {
    'es': 'Diseña tu minifigura y úsala en el runner.',
    'en': 'Design your minifig and use it in the runner.',
    'pt': 'Crie sua minifigura e use no runner.',
    'de': 'Gestalte deine Minifigur und nutze sie im Runner.',
    'ru': 'Создай минифигурку и используй её в раннере.',
    'fr': 'Conçois ta minifigurine et utilise-la dans le runner.',
  },

  // ── Galería de precargados ────────────────────────────────────────────────
  'preset_characters': {
    'es': 'Personajes precargados', 'en': 'Preset characters',
    'pt': 'Personagens prontos', 'de': 'Vorlagen-Figuren',
    'ru': 'Готовые персонажи', 'fr': 'Personnages prédéfinis',
  },
  'preset_intro': {
    'es': 'Elige un personaje para cargarlo con toda su configuración. Luego podrás cambiar lo que quieras antes de guardarlo.',
    'en': 'Pick a character to load it fully configured. Then change anything you like before saving.',
    'pt': 'Escolha um personagem para carregá-lo já configurado. Depois mude o que quiser antes de salvar.',
    'de': 'Wähle eine Figur, um sie fertig eingerichtet zu laden. Danach kannst du vor dem Speichern alles ändern.',
    'ru': 'Выбери персонажа, чтобы загрузить его со всеми настройками. Потом измени всё, что хочешь, перед сохранением.',
    'fr': 'Choisis un personnage pour le charger entièrement configuré. Modifie ensuite ce que tu veux avant d’enregistrer.',
  },
  'collection_golden_ninjas': {
    'es': 'Ninjas dorados', 'en': 'Golden Ninjas', 'pt': 'Ninjas dourados',
    'de': 'Goldene Ninjas', 'ru': 'Золотые ниндзя', 'fr': 'Ninjas dorés',
  },
  'collection_superheroes': {
    'es': 'Superhéroes', 'en': 'Superheroes', 'pt': 'Super-heróis',
    'de': 'Superhelden', 'ru': 'Супергерои', 'fr': 'Super-héros',
  },

  // ── Tienda ────────────────────────────────────────────────────────────────
  'store_title': {
    'es': 'Tienda', 'en': 'Store', 'pt': 'Loja',
    'de': 'Shop', 'ru': 'Магазин', 'fr': 'Boutique',
  },
  'store_restore': {
    'es': 'Restaurar', 'en': 'Restore', 'pt': 'Restaurar',
    'de': 'Wiederherstellen', 'ru': 'Восстановить', 'fr': 'Restaurer',
  },
  'gems_label': {
    'es': 'gemas', 'en': 'gems', 'pt': 'gemas',
    'de': 'Edelsteine', 'ru': 'кристаллы', 'fr': 'gemmes',
  },
  'gems_available': {
    'es': 'gemas disponibles', 'en': 'gems available', 'pt': 'gemas disponíveis',
    'de': 'Edelsteine verfügbar', 'ru': 'кристаллов доступно', 'fr': 'gemmes disponibles',
  },
  'badge_no_ads': {
    'es': 'Sin ads', 'en': 'No ads', 'pt': 'Sem ads',
    'de': 'Keine Ads', 'ru': 'Без рекламы', 'fr': 'Sans pub',
  },
  'redeem_gems_for_prizes': {
    'es': 'Canjear gemas por premios', 'en': 'Redeem gems for prizes',
    'pt': 'Trocar gemas por prêmios', 'de': 'Edelsteine gegen Preise tauschen',
    'ru': 'Обменять кристаллы на призы', 'fr': 'Échanger des gemmes contre des prix',
  },
  'vip_daily_title': {
    'es': 'Regalo diario VIP', 'en': 'Daily VIP gift', 'pt': 'Presente diário VIP',
    'de': 'Tägliches VIP-Geschenk', 'ru': 'Ежедневный VIP-подарок', 'fr': 'Cadeau VIP quotidien',
  },
  'vip_daily_subtitle': {
    'es': '+{n} 💎 cada día', 'en': '+{n} 💎 every day', 'pt': '+{n} 💎 por dia',
    'de': '+{n} 💎 pro Tag', 'ru': '+{n} 💎 каждый день', 'fr': '+{n} 💎 chaque jour',
  },
  'vip_claim': {
    'es': 'Reclamar', 'en': 'Claim', 'pt': 'Resgatar',
    'de': 'Abholen', 'ru': 'Забрать', 'fr': 'Réclamer',
  },
  'vip_tomorrow': {
    'es': 'Mañana', 'en': 'Tomorrow', 'pt': 'Amanhã',
    'de': 'Morgen', 'ru': 'Завтра', 'fr': 'Demain',
  },
  'vip_gift_snack': {
    'es': '¡Regalo VIP: +{n} 💎!', 'en': 'VIP gift: +{n} 💎!',
    'pt': 'Presente VIP: +{n} 💎!', 'de': 'VIP-Geschenk: +{n} 💎!',
    'ru': 'VIP-подарок: +{n} 💎!', 'fr': 'Cadeau VIP : +{n} 💎 !',
  },
  'vip_already_claimed': {
    'es': 'Ya reclamaste tu regalo VIP de hoy.',
    'en': 'You already claimed your VIP gift today.',
    'pt': 'Você já resgatou seu presente VIP de hoje.',
    'de': 'Du hast dein VIP-Geschenk heute schon abgeholt.',
    'ru': 'Ты уже забрал сегодняшний VIP-подарок.',
    'fr': 'Tu as déjà réclamé ton cadeau VIP aujourd’hui.',
  },
  'store_stub_banner': {
    'es': 'Compras simuladas (modo desarrollo). Se conectará el pago real al publicar en las tiendas.',
    'en': 'Simulated purchases (dev mode). Real payment will be connected on store release.',
    'pt': 'Compras simuladas (modo dev). O pagamento real será conectado ao publicar nas lojas.',
    'de': 'Simulierte Käufe (Dev-Modus). Echte Zahlung wird beim Store-Release angebunden.',
    'ru': 'Симуляция покупок (режим разработки). Реальная оплата подключится при публикации.',
    'fr': 'Achats simulés (mode dev). Le paiement réel sera connecté à la publication.',
  },
  'owned': {
    'es': 'Adquirido', 'en': 'Owned', 'pt': 'Adquirido',
    'de': 'Gekauft', 'ru': 'Куплено', 'fr': 'Acquis',
  },
  'already_owned': {
    'es': 'Ya tienes "{title}".', 'en': 'You already own "{title}".',
    'pt': 'Você já tem "{title}".', 'de': 'Du besitzt "{title}" bereits.',
    'ru': 'У тебя уже есть «{title}».', 'fr': 'Tu possèdes déjà « {title} ».',
  },
  'purchase_done': {
    'es': '¡Listo! "{title}" desbloqueado.',
    'en': 'Done! "{title}" unlocked.',
    'pt': 'Pronto! "{title}" desbloqueado.',
    'de': 'Fertig! "{title}" freigeschaltet.',
    'ru': 'Готово! «{title}» разблокировано.',
    'fr': 'Fait ! « {title} » débloqué.',
  },
  'purchase_failed': {
    'es': 'No se pudo completar la compra.',
    'en': 'The purchase could not be completed.',
    'pt': 'Não foi possível concluir a compra.',
    'de': 'Der Kauf konnte nicht abgeschlossen werden.',
    'ru': 'Не удалось завершить покупку.',
    'fr': 'L’achat n’a pas pu être finalisé.',
  },
  'iap_already_owned': {
    'es': 'Ya tienes este producto.', 'en': 'You already own this product.',
    'pt': 'Você já tem este produto.', 'de': 'Du besitzt dieses Produkt bereits.',
    'ru': 'У тебя уже есть этот товар.', 'fr': 'Tu possèdes déjà ce produit.',
  },
  'iap_store_unavailable': {
    'es': 'La tienda no está disponible.', 'en': 'The store is not available.',
    'pt': 'A loja não está disponível.', 'de': 'Der Shop ist nicht verfügbar.',
    'ru': 'Магазин недоступен.', 'fr': 'La boutique n’est pas disponible.',
  },
  'iap_product_not_found': {
    'es': 'Producto no encontrado en la tienda (revisa el SKU "{id}").',
    'en': 'Product not found in the store (check SKU "{id}").',
    'pt': 'Produto não encontrado na loja (verifique o SKU "{id}").',
    'de': 'Produkt im Shop nicht gefunden (prüfe SKU "{id}").',
    'ru': 'Товар не найден в магазине (проверь SKU «{id}»).',
    'fr': 'Produit introuvable dans la boutique (vérifie le SKU « {id} »).',
  },
  'iap_purchase_error': {
    'es': 'Error en la compra.', 'en': 'Purchase error.',
    'pt': 'Erro na compra.', 'de': 'Kauffehler.',
    'ru': 'Ошибка покупки.', 'fr': 'Erreur d’achat.',
  },
  'iap_purchase_canceled': {
    'es': 'Compra cancelada.', 'en': 'Purchase canceled.',
    'pt': 'Compra cancelada.', 'de': 'Kauf abgebrochen.',
    'ru': 'Покупка отменена.', 'fr': 'Achat annulé.',
  },
  'purchases_restored': {
    'es': 'Compras restauradas.', 'en': 'Purchases restored.',
    'pt': 'Compras restauradas.', 'de': 'Käufe wiederhergestellt.',
    'ru': 'Покупки восстановлены.', 'fr': 'Achats restaurés.',
  },

  // ── Canjería de gemas ─────────────────────────────────────────────────────
  'redeem_gems_title': {
    'es': 'Canjear gemas', 'en': 'Redeem gems', 'pt': 'Trocar gemas',
    'de': 'Edelsteine einlösen', 'ru': 'Обменять кристаллы', 'fr': 'Échanger des gemmes',
  },
  'redeem_prefix': {
    'es': 'Canjear {title}', 'en': 'Redeem {title}', 'pt': 'Trocar {title}',
    'de': '{title} einlösen', 'ru': 'Обменять {title}', 'fr': 'Échanger {title}',
  },
  'costs_label': {
    'es': 'Cuesta ', 'en': 'Costs ', 'pt': 'Custa ',
    'de': 'Kostet ', 'ru': 'Стоит ', 'fr': 'Coûte ',
  },
  'redeem_action': {
    'es': 'Canjear', 'en': 'Redeem', 'pt': 'Trocar',
    'de': 'Einlösen', 'ru': 'Обменять', 'fr': 'Échanger',
  },
  'redeemed_done': {
    'es': '¡Canjeado! "{title}".', 'en': 'Redeemed! "{title}".',
    'pt': 'Trocado! "{title}".', 'de': 'Eingelöst! "{title}".',
    'ru': 'Обменяно! «{title}».', 'fr': 'Échangé ! « {title} ».',
  },
  'not_enough_gems_store': {
    'es': 'No tienes suficientes gemas. Consíguelas en la Tienda.',
    'en': 'Not enough gems. Get them in the Store.',
    'pt': 'Gemas insuficientes. Consiga-as na Loja.',
    'de': 'Nicht genug Edelsteine. Hol sie im Shop.',
    'ru': 'Недостаточно кристаллов. Получи их в магазине.',
    'fr': 'Pas assez de gemmes. Obtiens-en dans la Boutique.',
  },
  'not_enough_gems': {
    'es': 'No tienes suficientes gemas.', 'en': 'Not enough gems.',
    'pt': 'Gemas insuficientes.', 'de': 'Nicht genug Edelsteine.',
    'ru': 'Недостаточно кристаллов.', 'fr': 'Pas assez de gemmes.',
  },

  // ── Ruleta diaria ─────────────────────────────────────────────────────────
  'roulette_title': {
    'es': 'Ruleta Diaria', 'en': 'Daily Wheel', 'pt': 'Roleta Diária',
    'de': 'Tägliches Rad', 'ru': 'Ежедневная рулетка', 'fr': 'Roue quotidienne',
  },
  'roulette_one_spin': {
    'es': '1 giro disponible hoy', 'en': '1 spin available today',
    'pt': '1 giro disponível hoje', 'de': '1 Dreh heute verfügbar',
    'ru': '1 вращение доступно сегодня', 'fr': '1 tour disponible aujourd’hui',
  },
  'roulette_spinning': {
    'es': '¡Girando!', 'en': 'Spinning!', 'pt': 'Girando!',
    'de': 'Dreht!', 'ru': 'Крутится!', 'fr': 'Ça tourne !',
  },
  'roulette_nice': {
    'es': '¡Genial!', 'en': 'Nice!', 'pt': 'Legal!',
    'de': 'Super!', 'ru': 'Класс!', 'fr': 'Super !',
  },
  'roulette_spin': {
    'es': '¡GIRAR!', 'en': 'SPIN!', 'pt': 'GIRAR!',
    'de': 'DREHEN!', 'ru': 'КРУТИТЬ!', 'fr': 'TOURNER !',
  },
  'roulette_prize': {
    'es': '¡Premio!', 'en': 'Prize!', 'pt': 'Prêmio!',
    'de': 'Preis!', 'ru': 'Приз!', 'fr': 'Prix !',
  },
  'roulette_coins': {
    'es': '{coins} monedas', 'en': '{coins} coins', 'pt': '{coins} moedas',
    'de': '{coins} Münzen', 'ru': '{coins} монет', 'fr': '{coins} pièces',
  },
  'roulette_already': {
    'es': '¡Ya reclamaste tu ruleta hoy!',
    'en': 'You already claimed your wheel today!',
    'pt': 'Você já resgatou sua roleta hoje!',
    'de': 'Du hast dein Rad heute schon geholt!',
    'ru': 'Ты уже забрал рулетку сегодня!',
    'fr': 'Tu as déjà réclamé ta roue aujourd’hui !',
  },
  'roulette_come_back': {
    'es': 'Vuelve mañana para girar de nuevo.',
    'en': 'Come back tomorrow to spin again.',
    'pt': 'Volte amanhã para girar de novo.',
    'de': 'Komm morgen wieder zum Drehen.',
    'ru': 'Возвращайся завтра, чтобы крутить снова.',
    'fr': 'Reviens demain pour tourner encore.',
  },
  'roulette_won_today': {
    'es': 'HOY GANASTE', 'en': 'YOU WON TODAY', 'pt': 'VOCÊ GANHOU HOJE',
    'de': 'HEUTE GEWONNEN', 'ru': 'СЕГОДНЯ ВЫИГРАНО', 'fr': 'GAGNÉ AUJOURD’HUI',
  },
  'roulette_next_spin': {
    'es': 'PRÓXIMO GIRO', 'en': 'NEXT SPIN', 'pt': 'PRÓXIMO GIRO',
    'de': 'NÄCHSTER DREH', 'ru': 'СЛЕДУЮЩЕЕ ВРАЩЕНИЕ', 'fr': 'PROCHAIN TOUR',
  },

  // ── Cofre ─────────────────────────────────────────────────────────────────
  'chest_vip': {
    'es': 'Cofre VIP', 'en': 'VIP Chest', 'pt': 'Baú VIP',
    'de': 'VIP-Truhe', 'ru': 'VIP-сундук', 'fr': 'Coffre VIP',
  },
  'chest_run': {
    'es': 'Cofre de Carrera', 'en': 'Run Chest', 'pt': 'Baú da Corrida',
    'de': 'Lauf-Truhe', 'ru': 'Сундук за забег', 'fr': 'Coffre de course',
  },
  'chest_nice': {
    'es': '¡Genial!', 'en': 'Nice!', 'pt': 'Legal!',
    'de': 'Super!', 'ru': 'Класс!', 'fr': 'Super !',
  },

  // ── Compuerta parental ────────────────────────────────────────────────────
  'parental_title': {
    'es': 'Control parental', 'en': 'Parental gate', 'pt': 'Controle parental',
    'de': 'Elternschutz', 'ru': 'Родительский контроль', 'fr': 'Contrôle parental',
  },
  'parental_prompt': {
    'es': 'Para continuar, pide a un adulto que resuelva:',
    'en': 'To continue, ask an adult to solve:',
    'pt': 'Para continuar, peça a um adulto para resolver:',
    'de': 'Zum Fortfahren bitte einen Erwachsenen, dies zu lösen:',
    'ru': 'Чтобы продолжить, попроси взрослого решить:',
    'fr': 'Pour continuer, demande à un adulte de résoudre :',
  },
  'parental_wrong': {
    'es': 'Respuesta incorrecta, inténtalo de nuevo.',
    'en': 'Wrong answer, try again.',
    'pt': 'Resposta incorreta, tente de novo.',
    'de': 'Falsche Antwort, versuch es nochmal.',
    'ru': 'Неверный ответ, попробуй снова.',
    'fr': 'Mauvaise réponse, réessaie.',
  },

  // ── Analítica (panel de depuración) ───────────────────────────────────────
  'analytics_title': {
    'es': 'Analítica (local)', 'en': 'Analytics (local)', 'pt': 'Análise (local)',
    'de': 'Analyse (lokal)', 'ru': 'Аналитика (локально)', 'fr': 'Analyse (locale)',
  },
  'analytics_reload': {
    'es': 'Recargar', 'en': 'Reload', 'pt': 'Recarregar',
    'de': 'Neu laden', 'ru': 'Обновить', 'fr': 'Recharger',
  },
  'analytics_clear': {
    'es': 'Borrar datos', 'en': 'Clear data', 'pt': 'Apagar dados',
    'de': 'Daten löschen', 'ru': 'Очистить данные', 'fr': 'Effacer les données',
  },
  'analytics_recent': {
    'es': 'Eventos recientes', 'en': 'Recent events', 'pt': 'Eventos recentes',
    'de': 'Letzte Ereignisse', 'ru': 'Недавние события', 'fr': 'Événements récents',
  },
  'analytics_no_events': {
    'es': 'Sin eventos todavía.', 'en': 'No events yet.', 'pt': 'Nenhum evento ainda.',
    'de': 'Noch keine Ereignisse.', 'ru': 'Событий пока нет.', 'fr': 'Aucun événement pour l’instant.',
  },
  'analytics_footer': {
    'es': 'Datos solo de este dispositivo (first-party). Para métricas agregadas de negocio se enviarán a un backend propio.',
    'en': 'Data from this device only (first-party). Aggregate business metrics will go to our own backend.',
    'pt': 'Dados apenas deste dispositivo (first-party). Métricas de negócio agregadas irão para um backend próprio.',
    'de': 'Daten nur von diesem Gerät (First-Party). Aggregierte Business-Metriken gehen an ein eigenes Backend.',
    'ru': 'Данные только с этого устройства (first-party). Сводные бизнес-метрики уйдут на собственный бэкенд.',
    'fr': 'Données de cet appareil uniquement (first-party). Les métriques agrégées iront vers notre propre backend.',
  },
  'analytics_sessions': {
    'es': 'Sesiones', 'en': 'Sessions', 'pt': 'Sessões',
    'de': 'Sitzungen', 'ru': 'Сессии', 'fr': 'Sessions',
  },
  'analytics_events': {
    'es': 'Eventos', 'en': 'Events', 'pt': 'Eventos',
    'de': 'Ereignisse', 'ru': 'События', 'fr': 'Événements',
  },
  'analytics_active_days': {
    'es': 'Días activos', 'en': 'Active days', 'pt': 'Dias ativos',
    'de': 'Aktive Tage', 'ru': 'Активные дни', 'fr': 'Jours actifs',
  },
  'analytics_runs': {
    'es': 'Carreras', 'en': 'Runs', 'pt': 'Corridas',
    'de': 'Läufe', 'ru': 'Забеги', 'fr': 'Courses',
  },
  'analytics_victories': {
    'es': 'Victorias', 'en': 'Victories', 'pt': 'Vitórias',
    'de': 'Siege', 'ru': 'Победы', 'fr': 'Victoires',
  },
  'analytics_win_rate': {
    'es': 'Tasa victoria', 'en': 'Win rate', 'pt': 'Taxa de vitória',
    'de': 'Siegquote', 'ru': 'Доля побед', 'fr': 'Taux de victoire',
  },
  'analytics_store': {
    'es': 'Tienda', 'en': 'Store', 'pt': 'Loja',
    'de': 'Shop', 'ru': 'Магазин', 'fr': 'Boutique',
  },
  'analytics_purchases': {
    'es': 'Compras', 'en': 'Purchases', 'pt': 'Compras',
    'de': 'Käufe', 'ru': 'Покупки', 'fr': 'Achats',
  },
  'analytics_conversion': {
    'es': 'Conversión', 'en': 'Conversion', 'pt': 'Conversão',
    'de': 'Conversion', 'ru': 'Конверсия', 'fr': 'Conversion',
  },
  'analytics_first_use': {
    'es': '1er uso', 'en': '1st use', 'pt': '1º uso',
    'de': 'Erste Nutzung', 'ru': '1-е исп.', 'fr': '1re util.',
  },

  // ── Editor: pestañas y encabezados ────────────────────────────────────────
  'editor_new_character': {
    'es': 'Nuevo personaje', 'en': 'New character', 'pt': 'Novo personagem',
    'de': 'Neue Figur', 'ru': 'Новый персонаж', 'fr': 'Nouveau personnage',
  },
  'editor_save_and_play': {
    'es': 'Guardar y jugar', 'en': 'Save and play', 'pt': 'Salvar e jogar',
    'de': 'Speichern und spielen', 'ru': 'Сохранить и играть', 'fr': 'Enregistrer et jouer',
  },
  'editor_saved': {
    'es': '¡Personaje guardado!', 'en': 'Character saved!', 'pt': 'Personagem salvo!',
    'de': 'Figur gespeichert!', 'ru': 'Персонаж сохранён!', 'fr': 'Personnage enregistré !',
  },
  'editor_name_label': {
    'es': 'NOMBRE', 'en': 'NAME', 'pt': 'NOME',
    'de': 'NAME', 'ru': 'ИМЯ', 'fr': 'NOM',
  },
  'editor_name_hint': {
    'es': 'Nombre del personaje', 'en': 'Character name', 'pt': 'Nome do personagem',
    'de': 'Name der Figur', 'ru': 'Имя персонажа', 'fr': 'Nom du personnage',
  },
  'editor_needs_name': {
    'es': 'El personaje necesita un nombre.',
    'en': 'The character needs a name.',
    'pt': 'O personagem precisa de um nome.',
    'de': 'Die Figur braucht einen Namen.',
    'ru': 'Персонажу нужно имя.',
    'fr': 'Le personnage a besoin d’un nom.',
  },
  'tab_head': {
    'es': 'Cabeza', 'en': 'Head', 'pt': 'Cabeça',
    'de': 'Kopf', 'ru': 'Голова', 'fr': 'Tête',
  },
  'tab_hair': {
    'es': 'Cabello', 'en': 'Hair', 'pt': 'Cabelo',
    'de': 'Haare', 'ru': 'Волосы', 'fr': 'Cheveux',
  },
  'tab_torso': {
    'es': 'Torso', 'en': 'Torso', 'pt': 'Torso',
    'de': 'Oberkörper', 'ru': 'Торс', 'fr': 'Torse',
  },
  'tab_legs': {
    'es': 'Piernas', 'en': 'Legs', 'pt': 'Pernas',
    'de': 'Beine', 'ru': 'Ноги', 'fr': 'Jambes',
  },
  'tab_accessories': {
    'es': 'Accesorios', 'en': 'Accessories', 'pt': 'Acessórios',
    'de': 'Extras', 'ru': 'Аксессуары', 'fr': 'Accessoires',
  },
  'sec_skin': {
    'es': 'Color de piel', 'en': 'Skin color', 'pt': 'Cor da pele',
    'de': 'Hautfarbe', 'ru': 'Цвет кожи', 'fr': 'Couleur de peau',
  },
  'sec_eyes': {
    'es': 'Ojos', 'en': 'Eyes', 'pt': 'Olhos',
    'de': 'Augen', 'ru': 'Глаза', 'fr': 'Yeux',
  },
  'sec_eyebrows': {
    'es': 'Cejas', 'en': 'Eyebrows', 'pt': 'Sobrancelhas',
    'de': 'Augenbrauen', 'ru': 'Брови', 'fr': 'Sourcils',
  },
  'sec_mouth': {
    'es': 'Boca', 'en': 'Mouth', 'pt': 'Boca',
    'de': 'Mund', 'ru': 'Рот', 'fr': 'Bouche',
  },
  'sec_facial_extra': {
    'es': 'Extras faciales', 'en': 'Facial extras', 'pt': 'Extras faciais',
    'de': 'Gesichts-Extras', 'ru': 'Детали лица', 'fr': 'Extras du visage',
  },
  'sec_type': {
    'es': 'Tipo', 'en': 'Type', 'pt': 'Tipo',
    'de': 'Typ', 'ru': 'Тип', 'fr': 'Type',
  },
  'sec_hair_style': {
    'es': 'Estilo de cabello', 'en': 'Hair style', 'pt': 'Estilo de cabelo',
    'de': 'Frisur', 'ru': 'Причёска', 'fr': 'Coiffure',
  },
  'sec_helmet_type': {
    'es': 'Tipo de casco', 'en': 'Helmet type', 'pt': 'Tipo de capacete',
    'de': 'Helmtyp', 'ru': 'Тип шлема', 'fr': 'Type de casque',
  },
  'sec_hat_type': {
    'es': 'Tipo de sombrero', 'en': 'Hat type', 'pt': 'Tipo de chapéu',
    'de': 'Huttyp', 'ru': 'Тип шляпы', 'fr': 'Type de chapeau',
  },
  'sec_torso_design': {
    'es': 'Diseño de torso', 'en': 'Torso design', 'pt': 'Design do torso',
    'de': 'Oberkörper-Design', 'ru': 'Дизайн торса', 'fr': 'Motif du torse',
  },
  'sec_cape': {
    'es': 'Capa', 'en': 'Cape', 'pt': 'Capa',
    'de': 'Umhang', 'ru': 'Плащ', 'fr': 'Cape',
  },
  'sec_gloves': {
    'es': 'Guantes', 'en': 'Gloves', 'pt': 'Luvas',
    'de': 'Handschuhe', 'ru': 'Перчатки', 'fr': 'Gants',
  },
  'sec_legs_design': {
    'es': 'Diseño de piernas', 'en': 'Legs design', 'pt': 'Design das pernas',
    'de': 'Beine-Design', 'ru': 'Дизайн ног', 'fr': 'Motif des jambes',
  },
  'sec_shoes': {
    'es': 'Zapatos', 'en': 'Shoes', 'pt': 'Sapatos',
    'de': 'Schuhe', 'ru': 'Обувь', 'fr': 'Chaussures',
  },
  'opt_none': {
    'es': 'Ninguno', 'en': 'None', 'pt': 'Nenhum',
    'de': 'Keiner', 'ru': 'Нет', 'fr': 'Aucun',
  },
  'unlock_prefix': {
    'es': 'Desbloquear {name}', 'en': 'Unlock {name}', 'pt': 'Desbloquear {name}',
    'de': '{name} freischalten', 'ru': 'Открыть {name}', 'fr': 'Débloquer {name}',
  },
  'unlock_action': {
    'es': 'Desbloquear', 'en': 'Unlock', 'pt': 'Desbloquear',
    'de': 'Freischalten', 'ru': 'Открыть', 'fr': 'Débloquer',
  },
  'coins_amount': {
    'es': '{n} monedas', 'en': '{n} coins', 'pt': '{n} moedas',
    'de': '{n} Münzen', 'ru': '{n} монет', 'fr': '{n} pièces',
  },
  'you_have_coins': {
    'es': 'Tienes: 🪙 {n}', 'en': 'You have: 🪙 {n}', 'pt': 'Você tem: 🪙 {n}',
    'de': 'Du hast: 🪙 {n}', 'ru': 'У тебя: 🪙 {n}', 'fr': 'Tu as : 🪙 {n}',
  },
  'not_enough_coins': {
    'es': 'No tienes suficientes monedas.\n¡Juega para ganar más!',
    'en': 'Not enough coins.\nPlay to earn more!',
    'pt': 'Moedas insuficientes.\nJogue para ganhar mais!',
    'de': 'Nicht genug Münzen.\nSpiele, um mehr zu verdienen!',
    'ru': 'Недостаточно монет.\nИграй, чтобы заработать ещё!',
    'fr': 'Pas assez de pièces.\nJoue pour en gagner plus !',
  },

  // Slots de accesorios
  'slot_rightHand': {
    'es': 'Mano derecha', 'en': 'Right hand', 'pt': 'Mão direita',
    'de': 'Rechte Hand', 'ru': 'Правая рука', 'fr': 'Main droite',
  },
  'slot_leftHand': {
    'es': 'Mano izquierda', 'en': 'Left hand', 'pt': 'Mão esquerda',
    'de': 'Linke Hand', 'ru': 'Левая рука', 'fr': 'Main gauche',
  },
  'slot_back': {
    'es': 'Espalda', 'en': 'Back', 'pt': 'Costas',
    'de': 'Rücken', 'ru': 'Спина', 'fr': 'Dos',
  },
  'slot_shoulders': {
    'es': 'Hombros', 'en': 'Shoulders', 'pt': 'Ombros',
    'de': 'Schultern', 'ru': 'Плечи', 'fr': 'Épaules',
  },
  'slot_waist': {
    'es': 'Cintura', 'en': 'Waist', 'pt': 'Cintura',
    'de': 'Taille', 'ru': 'Пояс', 'fr': 'Taille',
  },
  'slot_neck': {
    'es': 'Cuello', 'en': 'Neck', 'pt': 'Pescoço',
    'de': 'Hals', 'ru': 'Шея', 'fr': 'Cou',
  },
  'slot_face': {
    'es': 'Cara', 'en': 'Face', 'pt': 'Rosto',
    'de': 'Gesicht', 'ru': 'Лицо', 'fr': 'Visage',
  },
  'slot_feet': {
    'es': 'Pies', 'en': 'Feet', 'pt': 'Pés',
    'de': 'Füße', 'ru': 'Ноги', 'fr': 'Pieds',
  },
};
