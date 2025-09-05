# Pond Portal

_Embrace chaos and **dive** into the pond to teleport to another dimension..._

## Settings

```py
var default_config := {
     ## When allowMature is true, Pond Portal permits going to servers marked as mature
     ## They are otherwise excluded from the pool of lobby candidates, by default
    "allowMature": false
    ## Whether to message when arriving
    "sendGreetingMessage": true,
    ## Custom greeting message
    "greetingMessage": "arrived through the Pond Portal... neat!",
    ## Whether to message when leaving
    "sendPartingMessage": true,
    ## Custom parting message
    "partingMessage": "jumped into the Pond Portal and went to another dimension. Bye!",
    ## If set to false, disables using portals while hosting a lobby, as a safeguard
    "allowWhenLobbyHost": true,
    ## If set to false disables using portals from *the main lake*, as a safeguard
    ## You will have to use the smaller ponds on the right side of the island
    "allowLakePortal": true,
    ## If set to false the cool sound effect is muted
    "playPortalSound": true,
    ## Servers with fewer than this number of players will be filtered out
    "minimumLobbyPopulation": 1
}
```

## Changelog

### 1.4.0 OK, One more thing

- Taking a portal sends you to the same position from whence you departed
- Added setting `minimumLobbyPopulation`

### 1.3.0 Added tons of settings - check em out

### 1.2.1

- Added portal sound effects
- Changed portal to only activate in lake/ponds
- Fixed mature lobby setting defaulting to true (sorry!)
