Nov 2023

Personal Project - Missing complete documentation

A proof of concept subsurface scattering shader that can be implemented in later projects. Also includes a bloom postprocessing filter.

Each version implements a more complex version of the shader:
- V1: Implements back translucency
- V2: Adds subsurface distortion
- V3: Uses a local thickness map
- V4: Implemented with the unity PBS system, and uses the bloom filter

This shader is informed Alan Zucconi's tutorial: https://www.alanzucconi.com/2017/08/30/fast-subsurface-scattering-1/

This shader is designed to be fast and only use locally available information. Notably the local thickness map is quite challenging to generate effectively. Better results can be obtained by using raytracing or ray-marching.

![alt text](https://github.com/fennkm/Subsurface-Scattering-Experiment/blob/main/Thumbnail.PNG?raw=true)
