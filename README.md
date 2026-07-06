# -Glutamate-AMPAR-tuning-manuscript

[![DOI](https://zenodo.org/badge/1287469700.svg)](https://doi.org/10.5281/zenodo.21224276)

Contains MATLAB scripts used to perform analysis for calcium imaging and nonstationary fluctuation analysis in Banumurthy et al. 2026

Scripts used to analyze line scan images and electrophysiology data in our manuscript entitled 'Glutamate concentration tuned AMPAR funciton through conductance-state occupancy' in Nature Neuroscience. Scripts used to analyze line scans are identical to those used in our manuscript 'Afferent convergence onto a shared population of interneuron AMPA receptors' published in Nature Communications in 2023.

1) AlignImages.m
    -This script is used to align individual line scan sweeps spatially so that accurate analysis of the amplitude and spread of 
     fluorescence signals can be performed. Make sure that the width (spatial dimension) and length (temporal dimension) of all
     images is equal or there will be an error. Images from a channel detecting a fill dye (e.g. Alexa 594) and a fluorescent indicator
     (e.g. Fluo5F) are needed for each sweep.
    -Make sure images are named sequentially so that cropped images produced by this script are in the correct order (e.g. 010123_Cell1_Fluo5F_001, *_002, etc.)
     Indicate sweeps where failures occurred (e.g. 010123_Cell1_Fluo5F_F003). This will allow the next script in the work flow to separate
     sweeps with a signal from sweeps with failures.
    -The script will detect all images for each channel then detect peaks in the fluorescene of the dye channel. The user will then be 
     prompted to select a peak to crop the image around. There is an option to manually change the values for the peaks if needed if there 
     is poor detection on a small number of sweeps.
    -Cropped images will be placed in a new folder using the file names indicated.

2) CalculateTransients.m
    -The cropped images produced in (1) will now be used to calculate deltaG/R and deltaG/G. The sweeps with a signal present must be indicated
     before running the script. If sweeps with failures were named as suggested above this will be simple. If not each sweep with a signal will need
     to be indicated individually. The onset of any provided stimulus and the sampling rate of the line scans being analyzed will also need to be
     indicated.
    -ftWidth variable defines the number of pixels in the spatial dimension used to calculate dG/R and dG/G.
    -Filter parameters and scale bars can be adjusted as needed.
    -Upon running script an image of dG/R or dG/G will appear to allow the visualization of the signals before selecting the center of the signals.
     Dashed lines are placed at regular intervals to help with accurate centering of the signal when calculating dG/R or dG/G. Multiple runs
     may be required in some cases to get this correct.
    -Sweeps containing a signal will be averaged and plotted as a trace of dG/R or dG/G as a function of time. A similar trace will be overlaid
     for sweeps where failures occurred.
    -Raw data for these traces will be saved as .txt files in a new folder titled 'dGoverR' and 'dGoverG'

3) peak_scaled_nsfa.m
    -Electrophysiology files were acquired using Clampex 10.7 (.abf files) and sorted and analyzed using AxoGraph (saved as .axgx). AxoGraph files were     then exported as MATLAB files (.m). Analysis requires two files, one containing all sweeps individually and a second that contains the average EPSC     waveform.
    -Name files as indicated in comments of script, e.g. 'Date_Cell_EPSCs.mat' and 'Date_Cell_avg_EPSC.mat'
    -The number of data points used for analysis, sampling rate of the file and size of bins can all be adjusted in the first code section
