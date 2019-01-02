# exploring_maps_by_sounds
Project created for my Master thesis to sonify a Digital Elevation Model by using Parameter Mapping Sonification

## Description
This work presents an approach that uses Parameter Mapping Sonification (PMS) to represent a 2.5D elevation model not visually, but aurally by sonification. Three sonification parametrizations have been developed based on musicological rules and various findings of acoustic perception and information processing. Following, it was evaluated in a study with 61 participants, which parametrization could most effectively be interpreted. Furthermore, it has been investigated, to which extent previous knowledge helped to interpret the auditory display most effectively.

The study revealed that participants are indeed able to correctly interpret continuous data models and that previous knowledge contributes to successful auditory display interpretation. Furthermore, the following parametrization could be interpreted most effectively:
![Final auditory display model: W/E = pan between L and R || N/S = pan between square and sine wave || up/down = pitch +/-](http://www.geo.uzh.ch/~jschito/images/modell_b_2015_v2.png)

## Files
The input file (res/DEM.txt) represents a 2.5D Digital Elevation Model of parts of Switzerland (provided by Swisstopo). The output file that is generated (mousePositions.txt) lists the mouse positions and all mouse clicks and key presses that have been used to retrieve information out of the Auditory Display.

## Key Mapping
- F = sets a new start point
- E = sets a new end point
- M = mutes both audio outputs
- SHIFT = only sine wave hearable
- CTRL = only square wave hearable
- LEFT = only left output hearable
- RIGHT = only right output hearable
- UP = highest pitch
- DOWN = lowest pitch
- ESC = abort application

## Instructions and Parametrization
Ideally, set the screen resolution at least to 1280 x 800 pixel and wait a few seconds until the DEM has been loaded. Then, move your mouse and try to retrieve the information behind the sound by comparing the sound you hear with those of the legend. Use headphones for a better comprehension. A very deep sound (one octave deeper as the lowest pitch of the legend) indicates you a pixel without data. Facilitate your exploration by using the profile drawer keys F and E. If the application seems not to work properly, press F again.

- x-axis = balance (pan) between left (West) and right (East) ear
- y-axis = balance (pan) between square (North) and sine (South) wave 
- z-axis = pitch of one octave between 440 Hz (lowest point) and 880 Hz (highest point)

## Links
- Scientific research paper on https://www.tandfonline.com/doi/abs/10.1080/13658816.2017.1420192
- More information about the project on http://www.geo.uzh.ch/~jschito/
