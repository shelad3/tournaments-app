import 'package:flutter/material.dart';

class GameCategory {
  final String name;
  final IconData icon;
  final List<String> games;

  const GameCategory({required this.name, required this.icon, required this.games});
}

final List<GameCategory> gameCategories = [
  GameCategory(name: 'Soccer', icon: Icons.sports_soccer, games: [
    'EA Sports FC 26', 'EA Sports FC 25', 'EA Sports FC Mobile',
    'eFootball 2026', 'FIFA Mobile', 'Rocket League',
    'Football Manager 2026', 'Dream League Soccer', 'Score! Hero',
    'Captain Tsubasa', 'SuperCup', 'UFL',
  ]),
  GameCategory(name: 'Battle Royale', icon: Icons.shield, games: [
    'PUBG Mobile', 'PUBG PC', 'PUBG: New State',
    'Fortnite', 'Apex Legends',
    'Free Fire', 'Free Fire MAX',
    'Call of Duty: Warzone', 'Call of Duty: Warzone Mobile',
    'Fall Guys', 'Knives Out', 'Rules of Survival',
  ]),
  GameCategory(name: 'FPS / Shooters', icon: Icons.sports_kabaddi, games: [
    'Call of Duty: Black Ops 7', 'Call of Duty: Modern Warfare IV',
    'Call of Duty: Mobile', 'Call of Duty: Warzone Mobile',
    'Valorant', 'Counter-Strike 2', 'Rainbow Six Siege',
    'Overwatch 2', 'Battlefield 2042', 'Battlefield V',
    'Destiny 2', 'Apex Legends', 'XDefiant', 'The Finals',
    'Delta Force', 'Bodycam', 'S.T.A.L.K.E.R. 2',
  ]),
  GameCategory(name: 'MOBA', icon: Icons.groups, games: [
    'League of Legends', 'Dota 2', 'Mobile Legends: Bang Bang',
    'Wild Rift', 'Arena of Valor', 'Smite',
    'Heroes of the Storm', 'Pokémon Unite', 'Onmyoji Arena',
    'Vainglory', 'Battlerite',
  ]),
  GameCategory(name: 'Racing', icon: Icons.speed, games: [
    'Need for Speed Unbound', 'Forza Motorsport', 'Forza Horizon 5',
    'Gran Turismo 7', 'Gran Turismo Sport',
    'Asphalt 9: Legends', 'Asphalt 8', 'Mario Kart 8 Deluxe',
    'F1 26', 'F1 Mobile', 'Codemasters F1',
    'Dirt Rally 2.0', 'Trackmania', 'BeamNG.drive',
    'Assetto Corsa Competizione', 'CarX Street',
  ]),
  GameCategory(name: 'Fighting', icon: Icons.sports_mma, games: [
    'Street Fighter 6', 'Mortal Kombat 1', 'Tekken 8',
    'Super Smash Bros Ultimate', 'Dragon Ball FighterZ',
    'Dragon Ball Sparking! Zero', 'Guilty Gear Strive',
    'King of Fighters XV', 'MultiVersus', 'Brawlhalla',
    'Naruto x Boruto: Ultimate Ninja Storm',
  ]),
  GameCategory(name: 'Sports', icon: Icons.fitness_center, games: [
    'NBA 2K26', 'NBA 2K25', 'Madden NFL 26',
    'WWE 2K25', 'WWE 2K24', 'WWE SuperCard',
    'UFC 5',     'EA Sports College Football 26',
    'Cricket 25', 'Cricket 24',
    'Tony Hawk\'s Pro Skater 1+2',
    'PGA Tour 2K26', 'Mario Golf', 'Everybody\'s Golf',
  ]),
  GameCategory(name: 'Strategy', icon: Icons.psychology, games: [
    'StarCraft II', 'Age of Empires IV', 'Age of Empires Mobile',
    'Clash of Clans', 'Clash Royale', 'Boom Beach',
    'Civilization VII',
    'Total War: Warhammer III', 'Total War: Pharaoh',
    'Company of Heroes 3', 'XCOM 2', 'Frostpunk',
    'Hearts of Iron IV', 'Europa Universalis IV',
  ]),
  GameCategory(name: 'Open World / Sandbox', icon: Icons.public, games: [
    'Grand Theft Auto V', 'Grand Theft Auto Online',
    'Grand Theft Auto VI', 'Minecraft', 'Minecraft Bedrock',
    'Roblox', 'Fortnite', 'Red Dead Redemption 2',
    'Cyberpunk 2077', 'Elden Ring', 'Skyrim',
    'Starfield', 'The Witcher 3', 'Sons of the Forest',
    'Palworld', 'No Man\'s Sky', 'Terraria',
  ]),
  GameCategory(name: 'Card / Board', icon: Icons.casino, games: [
    'Hearthstone', 'Magic: The Gathering Arena',
    'Yu-Gi-Oh! Master Duel', 'Pokémon TCG Live',
    'Marvel Snap', 'Gwent', 'Legends of Runeterra',
    'UNO', 'Chess.com', 'Chess Titans',
    'Monopoly Go!', 'Ludo King', 'Exploding Kittens',
    'Skat', 'Durak Online',
  ]),
  GameCategory(name: 'Fitness / Dance', icon: Icons.directions_run, games: [
    'Just Dance 2026', 'Just Dance 2025',
    'Ring Fit Adventure', 'Beat Saber',
    'Fitness Boxing', 'Nintendo Switch Sports',
    'Dance Dance Revolution', 'Synth Riders',
    'Zumba Burn It Up!',
  ]),
  GameCategory(name: 'Simulation', icon: Icons.flight, games: [
    'Microsoft Flight Simulator 2026', 'Microsoft Flight Simulator',
    'The Sims 4', 'Cities: Skylines II', 'Planet Coaster 2',
    'Planet Zoo', 'Two Point Hospital', 'Stardew Valley',
    'Animal Crossing: New Horizons', 'Euro Truck Simulator 2',
    'Farming Simulator 27', 'PowerWash Simulator',
    'House Flipper 2', 'Gas Station Simulator',
  ]),
  GameCategory(name: 'Horror', icon: Icons.dangerous, games: [
    'Resident Evil 4 Remake', 'Resident Evil Village',
    'Silent Hill 2 Remake', 'Dead by Daylight',
    'Phasmophobia', 'The Outlast Trials',
    'Alan Wake 2', 'Five Nights at Freddy\'s',
    'Outlast', 'Amnesia: The Bunker',
    'Little Nightmares III', 'Lethal Company',
    'Poppy Playtime', 'Cry of Fear',
  ]),
  GameCategory(name: 'Anime / Manga', icon: Icons.auto_awesome, games: [
    'Genshin Impact', 'Honkai: Star Rail', 'Zenless Zone Zero',
    'Wuthering Waves', 'Naruto x Boruto',
    'Dragon Ball Z: Kakarot', 'One Piece: Pirate Warriors 4',
    'Demon Slayer: Hinokami Chronicles',
    'Jujutsu Kaisen: Cursed Clash',
    'My Hero Ultra Rumble', 'Blue Lock',
    'Sword Art Online', 'Tower of Fantasy',
  ]),
  GameCategory(name: 'Mobile Casual', icon: Icons.phone_android, games: [
    'Candy Crush Saga', 'Subway Surfers', 'Temple Run 2',
    'Angry Birds 2', 'Hill Climb Racing', 'Plants vs Zombies 2',
    '8 Ball Pool', 'Clash of Clans', 'Clash Royale',
    'Brawl Stars', 'Among Us', 'Wordle',
    'Royal Match', 'Coin Master', 'Dumb Ways to Survive',
  ]),
];

const List<String> platforms = [
  'PC',
  'PlayStation 5',
  'PlayStation 4',
  'Xbox Series X|S',
  'Xbox One',
  'Mobile (Android)',
  'Mobile (iOS)',
  'Nintendo Switch',
  'Cross-Platform',
  'Cloud Gaming',
];

List<String> allGamesList() {
  final list = gameCategories.expand((cat) => cat.games).toList();
  list.sort();
  return list;
}
