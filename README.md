# OnTheFly_Opt_with_Configuration_Diffusion
## This script code do on-the-fly atomic cluster configuration sampling via atomic diffusion followed by structural optimization. 

Conf_Rand_Diffusion.sh is a bash script file, also the main executive script. 
It first reads in .xyz file containing the 3D atomic coordinates of those clusters to be investigated. It then carries out an initial optimization to get a reasonable structure (any third-party codes, either empirical or ab-initio quantum chemistry codes, using MOPAC in the example code). The MOPAC output file is then distilled, and the relevant atomic coordinates are perturbed by a small amount. The perturbed structure is again fed into MOPAC for optimization so that it reaches a different equilibrium point. To ensure that the structures are converging to low energy minimas, whether to accept or reject a newly-generated equilibrium structure for next seeding is mainly based on the Metropolis criteria with Boltzmann factor. 

By consecutively doing the above steps, we can search/obtain a series of structures with energy downhill trend via this diffusion process. The program outputs are .xyz files as well.
