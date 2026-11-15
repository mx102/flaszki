# Glossary

**Flask**: a container holding a vertical stack of Layers, up to its capacity.

**Layer**: one unit of fluid of a single Color inside a Flask.

**Color**: a fluid color. At most 12 distinct Colors exist in the game.

**Pour**: a player move from a source Flask to a target Flask. Moves all contiguous same-Color top Layers of the source that fit into the target.

**Level**: one puzzle instance: an initial arrangement of Flasks plus a Goal Queue. Identified by its Level Number; Level N is identical on every device.

**Level Number**: the player's progress counter; also determines the Level's content.

**Goal Queue**: ordered list of Colors shown at the top of the screen; the player must complete a Flask of the first Color in the queue next.
_Avoid_: target list, objectives
A Color may appear in the Goal Queue more than once. Only the next 4 entries are shown.

**Completed Flask**: a full Flask of a single Color. When its Color is at the head of the Goal Queue it is sealed and removed from the board, and the queue advances. A Completed Flask of another Color stays on the board until its Color reaches the head.

**Solved**: a Level whose Goal Queue is empty.

**Dead End**: a state from which the Level can no longer be Solved. Not a loss; the player can Undo or Restart.

**Breather**: a Level deliberately easier than the Levels around it; a rest in the ramp of difficulty.
