# DodgiBot
Better Dodgeball Bot

https://www.youtube.com/watch?v=jLIQqhKHmAQ

Type `!botmenu` in the chat to use it.

## Commands
```yaml
sm_botmenu      : Opens the main menu
sm_pvb          : Vote to enable or disable the bot (Alias: sm_votepvb)
sm_votediff     : Vote for difficulty (Alias: sm_votedif)
sm_votedeflects : Vote for deflects to win
sm_votesuper    : Vote for super reflect chance
sm_votemovement : Vote for bot movement (Alias: sm_votemove)
sm_revote       : Revote in the current poll
```

## Admin Commands
```yaml
sm_bot_toggle   : Force toggle the bot on/off
sm_bot_beatable : Toggle if the bot can be killed
```

## Configuration

### General
```ini
db_bot_name = "DodgiBot"
; The name that the bot will use in game

db_bot_difficulty = 0
; Sets the AI difficulty level (0 is Normal, 1 is Hard, 2 is Progressive)

db_bot_beatable = 0
; If set to 1 the bot can take damage and die, if 0 it is invincible

db_bot_victory_deflects = 60.0
; Number of deflects needed to win the round
```

### Gameplay
```ini
db_bot_react_min = 100.0
; The fastest reaction time in milliseconds

db_bot_react_max = 200.0
; The slowest reaction time in milliseconds

db_bot_prediction = 0.7
; How accurate the bot is at predicting rocket movement (0.0 to 1.0)

db_bot_flick_chance = "15.0 40.0 10.0 10.0 10.0 10.0 5.0"
; Percentage chances for different flick types (None Wave USpike DSpike LSpike RSpike BackShot)

db_bot_flick_chance_cqc = "5.0 10.0 25.0 25.0 10.0 10.0 15.0"
; Flick chances during close quarters combat
```

### Super Reflect
```ini
db_bot_super_reflect = 1
; If set to 1 the bot will try to aim at players instead of just reflecting

db_bot_super_chance = 0.0
; The probability (0.0 to 1.0) that the bot will use a super reflect
```

### Movement
```ini
db_bot_movement = 0
; If set to 1 the bot is allowed to move around

db_bot_orbit_enable = 1
; Enable or disable the orbiting system entirely

db_bot_orbit_chance = 20.0
; The percentage chance (0 to 100) that the bot will orbit around a rocket

db_bot_orbit_min = 2.0
; Minimum time in seconds to orbit

db_bot_orbit_max = 5.0
; Maximum time in seconds to orbit
```

### Voting
```ini
db_bot_vote_mode = 3
; Voting system mode (0 is Off, 1 is Chat only, 2 is Menu only, 3 is Both)

db_bot_vote_time = 25.0
; Time in seconds the vote menu should last

db_bot_vote_percent = 0.6
; The percentage of players required to pass a vote (0.0 to 1.0)

db_bot_vote_cooldown = 15.0
; Global cooldown time in seconds between ANY type of vote
```

### Visuals & Chat
```ini
db_bot_chat_tag = "{ORANGE}[DBBOT]"
; The prefix tag shown in chat messages

db_bot_chat_color_main = "{WHITE}"
; Main color for chat messages

db_bot_chat_color_key = "{DARKOLIVEGREEN}"
; Color for keywords in chat

db_bot_chat_color_client = "{TURQUOISE}"
; Color for player names in chat

db_bot_mode_name_beatable = "Beatable"
; Name for beatable mode in announcements

db_bot_mode_name_unbeatable = "Unbeatable"
; Name for unbeatable mode in announcements

db_bot_shield_radius = 200.0
; The radius of the bot's protective shield

db_bot_shield_force = 800.0
; The force applied by the shield to push players away
```
