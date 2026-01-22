# DodgiBot
Better Dodgeball Bot

https://www.youtube.com/watch?v=jLIQqhKHmAQ

Type `!botmenu` in the chat to use it.

## Commands
```yaml
sm_botmenu      : Opens the main menu
sm_pvb          : Vote to enable or disable the bot
sm_votediff     : Vote for difficulty
sm_votedeflects : Vote for deflects to win
sm_votesuper    : Vote for super reflect chance
sm_votemovement : Vote for bot movement
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
```

### Gameplay
```ini
db_bot_react_min = 100.0
; The fastest reaction time in milliseconds

db_bot_react_max = 200.0
; The slowest reaction time in milliseconds

db_bot_prediction = 0.7
; How accurate the bot is at predicting rocket movement (0.0 to 1.0)
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

db_bot_orbit_chance = 20.0
; The percentage chance (0 to 100) that the bot will orbit around a rocket

db_bot_orbit_speed = -1.0
; The maximum speed the bot can move while orbiting

db_bot_orbit_min = 0.0
; Minimum time in seconds to orbit

db_bot_orbit_max = 3.0
; Maximum time in seconds to orbit
```

### Voting
```ini
db_bot_vote_mode = 3
; Voting system mode (0 is Off, 1 is Chat only, 2 is Menu only, 3 is Both)

db_bot_vote_percent = 0.6
; The percentage of players required to pass a vote (0.0 to 1.0)

db_bot_vote_cooldown = 15.0
; The time in seconds between allowed votes
```

### Visuals
```ini
db_bot_chat_tag = "{ORANGE}[DBBOT]"
; The prefix tag shown in chat messages

db_bot_shield_radius = 200.0
; The radius of the bot's protective shield

db_bot_shield_force = 800.0
; The force applied by the shield to push players away
```
