# Untitled Game
A 3d beat-em-up style game built in Godot

## Alpha Release
Take it to the arena for an endless battle against hoards of enemies that want you dead.
Features include
- A basic inventory system
- Two difffenet types of enemies
  - One regular enemy and one boss
- A shop for upgrades and items
- A very basic (incomplete) save system
This release is meant to set a foundation for future development. Fundamental aspects such as controls and the game's structure will mostly remain the same until the final release. Most of what will be changed in the future will be additive instead of replacements. More enemy types, textures, and a major GUI overhaul will be implemented by the beta.

# Talk about these functions
```
func _on_shop_area_area_entered(area: Area3D) -> void:
```
```
func _on_shop_area_area_exited(area: Area3D) -> void:
```
```
func save():
```
```
func load_data()
```
Google Slides Presentation: https://docs.google.com/presentation/d/1gsCbGgn-dhi5o6xcioAFhJ7TlpuEUn5qaVwtCk7jeM0/edit?usp=sharing

## Beta Release
The work I did for the beta release was adding more variety in the fights.
- More types of enemies
  - Total of 3 regular enemies and 3 bosses (looking to at least double this by full release)
- Updated textures for the character and the bosses
- Redesigned UI with a minimap (still needs some work)
- Expanded title screen menu
  - Now has a music player
  - Began work on an options menu. Currently can toggle fullscreen.
- Updated enemy AI

The beta release is mostly an improved version of the alpha. No major changes in the way it plays, only expansions of ideas that I had already implemented.
Creating more enemy types was harder than I orginally thought it would be. The structure of the scripts were almost exactly the same, but what goes on inside it is extremely different between. This was tedious, even with the egregious amount of copy/pasting that was done.
The UI was a lot less headache inducing, as the copy/pasting I did with the scripts is pretty much all I needed to do

## Resources Used
- **Godot**: The game engine used to build the project. I chose it because learning a new language (C++ or C#) would be too much to finish within the time I'm given. It's also a bit more user friendly than Unreal Engine and I don't like Unity.
  - https://godotengine.org/
- **Blender**: For 3d modeling and animation organization. The main character model was created by me. I used a couple of add-ons to have better compatibilty with Godot and generally save me a lot of headache.
  - **Godot Game Tools**: Add-on for blender that applies multiple animations to one 3d model and exports it for compatibilty for Godot
    - https://github.com/vini-guerrero/godot_game_tools
  - https://www.blender.org/
- **Adobe Mixamo**: Premade animations made by Adobe that look better than anything I could do. Has almost everything I could have wanted to animate
  -  https://www.mixamo.com/
- And of course, random Youtube tutorials helped me with any question I had regarding how certain thing worked 

## Known Bugs
- Some animations playing when the're not supposed to
  - Player Character can get locked into the stun animation when not stunned
- GUI quirks to iron out
