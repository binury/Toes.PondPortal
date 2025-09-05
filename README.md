# Pond Portal

![Icon](https://i.imgur.com/9qnRJ3W.png 'Pond Portal icon')

_Embrace chaos and **dive** into the pond to visit another dimension..._

## [Changelog](https://thunderstore.io/c/webfishing/p/toes/Pond_Portal/changelog/)

## [Contributing (PRs welcome)](https://github.com/binury/Toes.PondPortal/pulls)

## [Known Issues](https://github.com/binury/Toes.PondPortal/issues?q=sort%3Aupdated-desc+is%3Aissue+is%3Aopen)

## [Feedback & Bug Reports (Discord)](https://discord.gg/kjf3FCAMDb)

## [Feature requests](https://github.com/binury/Toes.PondPortal/issues?q=sort%3Aupdated-desc%20is%3Aissue%20is%3Aopen%20label%3Aenhancement)

## Settings

```jsonc
{
     // When allowMature is true, Pond Portal permits going to servers marked as mature
     // They are otherwise excluded from the pool of lobby candidates, by default
    "allowMature": false,

    // Whether to message when arriving
    "sendGreetingMessage": true,

    // Custom greeting message
    "greetingMessage": "arrived through the Pond Portal... neat!",

    // Whether to message when leaving
    "sendPartingMessage": true,

    // Custom parting message
    "partingMessage": "jumped into the Pond Portal and went to another dimension. Bye!",

    // If set to false, disables using portals while hosting a lobby, as a safeguard
    "allowWhenLobbyHost": true,

    // If set to false disables using portals from *the main lake*, as a safeguard
    // You will have to use the smaller ponds on the right side of the island
    "allowLakePortal": true,

    // If set to false the cool sound effect is muted (why would you do this 😔)
    "playPortalSound": true,

    // Servers with fewer than this number of players will be filtered out
    "minimumLobbyPopulation": 1
}
```
