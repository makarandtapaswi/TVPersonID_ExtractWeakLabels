Weak Labels for PersonID in TV series
===========

This is a Matlab implementation of the paper:

----
Improved Weak Labels using Contextual Cues for Person Identification in Videos  
Makarand Tapaswi, Martin Bäuml, and Rainer Stiefelhagen  
IEEE International Conference on Automatic Face and Gesture Recognition (FG), 2015  
[Paper download](https://cvhci.anthropomatik.kit.edu/~mtapaswi/papers/FG2015.pdf) | [ShotThreading & SceneDetection code](https://github.com/makarandtapaswi/Video_ShotThread_SceneDetect)

----


### Tested on
Ubuntu 14.04 with Matlab version R2014a - R2015a.


### First initialization
The <code>first_init.m</code> script will be called on running <code>startup.m</code> the first time. This will ask you to install some external toolboxes. Please follow the instructions.

---
### Example usage
A video structure can be created by calling either  
<code>VS = BBT(1, 1);</code> or <code>VS = BUFFY(5, 1)</code>

The main function can be directly invoked with one or multiple videos at once.
<code>ft = speaking_face2_wrapper(BBT(1, 1:6));</code>

We include data for 6 episodes each of
- <em>The Big Bang Theory</em> ([BBT](http://en.wikipedia.org/wiki/The_Big_Bang_Theory)) season 1, episodes 1..6
- <em>Buffy the Vampire Slayer</em> ([BUFFY](http://en.wikipedia.org/wiki/Buffy_the_Vampire_Slayer)) season 5, episodes 1..6
as described in the paper.

For any questions about the generation of data, please contact me.


----
### External toolboxes
- [jsonlab](http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files-in-matlab-octave): Matlab JSON interface
- [DataHash](http://mathworks.com/matlabcentral/fileexchange/31272-datahash): Create a hash of parameters for caching
- [maximalCliques](http://mathworks.com/matlabcentral/fileexchange/30413-bron-kerbosch-maximal-clique-finding-algorithm): Computes maximal cliques
- [minmaxk](http://mathworks.com/matlabcentral/fileexchange/23576-min-max-selection): Min-k Max-k (in MEX!)

### Main functions
- [speaking_face2_wrapper.m](weak_labeling/speaking_face2_wrapper.m)  Main function which runs over all episodes
- [speaking_face2_prepare_data.m](weak_labeling/speaking_face2_prepare_data.m)  Prepares data, handles whether to use context such as threading and uniqueness
- [speaking_face2_optimize_fmincon.m](weak_labeling/speaking_face2_optimize_fmincon.m)  Runs <code>fmincon</code> with the correct options over all cliques
- [speaking_face2_fmincon_objfun.m](weak_labeling/speaking_face2_fmincon_objfun.m)  Contains the core objective function used to compute labeling scores for each face track clique


### Changelog
- 12-03-2015: A complete working example of the FG 2015 paper


