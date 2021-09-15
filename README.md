# plinko

## Intro
A simple simulation of the Plinko luck game. <br>
Made in Lua, using the LOVE 2D engine for graphics rendering.

## Features
* User controlled disc drop
* Multi level support
* Custom made physics engine
* Flexible game objects

## Thoughts

### Game Object
Game Object is used as a building block for the game.
* Child/Parent hierarchy. 
* Children updated by the parent. 
* Inherit a game object to build a scene and add all other objects to it.
* Move a parent to move its children with it.
* Convenient initialization of game elements.

### Physics
Physics is based around the Rigidbody class.
* Add rigidbody objects to game objects to detect their collisions.
* Rigidbody parasites on the game object using its methods for updates, without the game object being aware of it. (thanks Lua)
* Set collision category and mask to determine by what kind of objects can your object by affected in collision

### Structure
The main object is the PlinkoBoard that works as a scene. 

#### Scene: Plinko Board
* Contains all the object as its children.
* Updated by the LOVE 2D methods.
* Reloads the scene when needed, for a particular level.
* Levels procedurally generated if not manually.
* Checks win/lose conditions.

#### Elements: Play Area & Disc
* The only area where the disc can be dropped.
* The disc is a game object that is affected by pegs to bounce.

#### Elements: Pegs
* Peg is affected by disc to produce a sound effect.
* Pegs are ordered based on the numer of rows and the number of rewards.

#### Elements: Rewards
* Initialized with an array of reward values.
* Affected by the disc to. produce sound and increase score.
* Stores the state of being rewarded in the disc itself, without the disc being aware of it. (thanks Lua)
