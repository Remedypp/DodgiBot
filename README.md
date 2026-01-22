# DodgiBot
Better Dodgeball Bot

https://www.youtube.com/watch?v=jLIQqhKHmAQ

Type `!botmenu` in the chat to use it.

## Commands
sm_botmenu : Opens the main menu
sm_pvb : Vote to enable or disable the bot
sm_votediff : Vote for difficulty
sm_votedeflects : Vote for deflects to win
sm_votesuper : Vote for super reflect chance
sm_votemovement : Vote for bot movement

## Configuration

### General
db_bot_name : The name that the bot will use in game
db_bot_difficulty : Sets the AI difficulty level (0 is Normal, 1 is Hard, 2 is Progressive)
db_bot_beatable : If set to 1 the bot can take damage and die, if 0 it is invincible

### Gameplay
db_bot_react_min : The fastest reaction time in milliseconds (e.g. 100.0)
db_bot_react_max : The slowest reaction time in milliseconds (e.g. 200.0)
db_bot_prediction : How accurate the bot is at predicting rocket movement (0.0 to 1.0)

### Super Reflect
db_bot_super_reflect : If set to 1 the bot will try to aim at players instead of just reflecting
db_bot_super_chance : The probability (0.0 to 1.0) that the bot will use a super reflect

### Movement
db_bot_movement : If set to 1 the bot is allowed to move around
db_bot_orbit_chance : The percentage chance (0 to 100) that the bot will orbit around a rocket
db_bot_orbit_speed : The maximum speed the bot can move while orbiting
db_bot_orbit_min : Minimum time in seconds to orbit
db_bot_orbit_max : Maximum time in seconds to orbit

### Voting
db_bot_vote_mode : Voting system mode (0 is Off, 1 is Chat only, 2 is Menu only, 3 is Both)
db_bot_vote_percent : The percentage of players required to pass a vote (0.0 to 1.0)
db_bot_vote_cooldown : The time in seconds between allowed votes

### Visuals
db_bot_chat_tag : The prefix tag shown in chat messages
db_bot_shield_radius : The radius of the bot's protective shield
db_bot_shield_force : The force applied by the shield to push players away
