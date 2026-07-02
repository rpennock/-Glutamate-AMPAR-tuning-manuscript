edit peak_scaled_nsfa
clear

%traces exported from AxoGraph (.mat files)
%individual and average traces should be imported separately and file names
%should be constructed so that they can be distinguished with the dir function
%for expample 'Date_Cell_EPSCs_.mat' and 'Date_Cell_Avg_EPSC.mat'

ephysFilename=dir('060420_Cell1_EPSCs*');
avgEphysFilename=dir('060420_Cell1_avg_EPSCs*');

%Pick a term in the filename that is common to both files and can be used
%to name outputs
%e.g. using the 'Date_Cell_EPSCs_.mat'example when inputForStrFind='EPSCs'
%you will get files named 'Date_Cell_EPSCs_Mean_Variance.txt', etc.
%(line 134-140 in script)
inputForStrFind='EPSCs';

responseType='Synaptic'; 
% 'Synaptic' or 'Spillover', this is used to adjust the number of points 
% used to average around peak. 'Synaptic' uses 3 points, 'Spillover' uses 5
% both are hard coded and have to be changed in script (line 101-105)                    

sweepLength=650; %number of data points used from each sweep
                 %crops end of sweeps (lines 49-52 and 64-67) 

samplingRate=20; %in kHz
binSize=0.02; %fraction of peak current to use when binning by epsc amplitude
               % e.g. binSizes=0.02 will create 50 bins (some may be empty)
               % (lines 191-252)
binStart=0; %fraction of epsc tail removed from data, default to 0 unless
            %there is a specific reason not to

%create empty arrary to store the number of sweeps for each condition
sweepQuantity=zeros(1, length(ephysFilename));

%%
%import and crop files containing individual EPSCs and average EPSC

%import individual sweeps
ephysFileStruct=load(ephysFilename.name);
ephysFileCell=struct2cell(ephysFileStruct);
%if you just use the 'load(ephysfile.mat)' function it will load each
%sweep individually. Assigning a variable loads each file into a struc that
%can then be converted to a cell and be more easily manipulated

%crop the lengths of each sweep so that they are all equal
for jj=1:length(ephysFileCell)
        ephysFileCell{jj}=ephysFileCell{jj}(1:sweepLength);
        sweepQuantity=jj-1;
end

%convert cell with imported and cropped sweeps to a matrix
ephysFileMatrix=cell2mat(ephysFileCell);
%remove row with time dimension and convert from A to pA
ephysFileMatrix=ephysFileMatrix(2:end,:)*(10^12);

%import average EPSC
%repeats same script used above, only one sweep in this file
avgEphysFileStruct=load(avgEphysFilename.name);
avgEphysFileCell=struct2cell(avgEphysFileStruct);

for jj=1:length(avgEphysFileCell)
        avgEphysFileCell{jj}=avgEphysFileCell{jj}(1:sweepLength);
        sweepQuantity=jj-1;
end

avgEphysFileMatrix=cell2mat(avgEphysFileCell);
avgEphysFileMatrix=avgEphysFileMatrix(2,:)*(10^12);

%add time axis to individual and average sweeps
timeAxis=0:(1/samplingRate):((1/samplingRate)*(sweepLength-1));
ephysFileMatrix=[timeAxis; ephysFileMatrix];
avgEphysFileMatrix=[timeAxis; avgEphysFileMatrix];

%plot EPSCs
figure
plot(ephysFileMatrix(1,:), ephysFileMatrix(2:end,:))
title('all Epscs')
xlabel('ms')
ylabel('pA')

figure
plot(avgEphysFileMatrix(1,:), avgEphysFileMatrix(2:end,:))
title('avg EPSC')
xlabel('ms')
ylabel('pA')

%%
%Peak scale each sweep to the peak of the average EPSC

%find the max amplitude of the average sweep and the index of the max 
% use min function because of inward currents 
%****This script won't work with outward currents. An if/else statement or 
%****something would need to be added so that the max function could be used 
%****for outward currents
[peakAvgSweep, peakAvgSweepIndex]=min(avgEphysFileMatrix(2,:), [], 2);

%set number of points used for averaging around peak of each sweep
if contains(responseType, 'Synaptic')
   meanWindowSpan=1;
   elseif contains(responseType, 'Spillover')
          meanWindowSpan=2;
end

%for each EPSC isolate the point coincident with the peak of the average
%EPSC, as well as points flanking the peak (defined by 'meanWindowSpan')
%Average those points to get value to use for peak scaling
peakIndexAllSweeps=ephysFileMatrix(2:end,...
                                  peakAvgSweepIndex-meanWindowSpan:...
                                  peakAvgSweepIndex+meanWindowSpan);
peakAmplitudeAllSweeps=sum(peakIndexAllSweeps, 2)./(meanWindowSpan*2+1);

%use peak amplitude of average EPSC to calculate scalars for each sweep
scalarForPeaks=peakAvgSweep./peakAmplitudeAllSweeps;
%populate rows of matrix with scalar values
scalarForPeaksMatrix=repmat(scalarForPeaks, 1, sweepLength);

%element-wise multiplication of each EPSC with corresponding scalar
epscsScaled=ephysFileMatrix(2:end,:).*scalarForPeaksMatrix;
epscsScaled=[timeAxis; epscsScaled];

figure
plot(epscsScaled(1,:), epscsScaled(2:end,:))
title('scaled EPSCs')
xlabel('ms')
ylabel('pA')

%save scaled EPSCs, avg EPSC, scalars as txt files
mkdir('txt_files')
addpath('txt_files')

%create file name from 'ephysFilename', write as txt file
%import file name
fileName=[ephysFilename.name];
%find previously defined string earlier in script (e.g. 'EPSC')
dateCellExpCondition=strfind(fileName, inputForStrFind);
strLength=length(inputForStrFind);
%use filename up to the defined string
fileNameCropped=fileName(1:dateCellExpCondition+...
                           (strLength-1));
%scalars
fileNameScalars=[fileNameCropped '_scalars' '.txt'];
fileDestinationScalars=fullfile('txt_files', fileNameScalars);
writematrix(scalarForPeaks, fileDestinationScalars, 'Delimiter', 'tab');
%average EPSC
fileNameAvgEpsc=[fileNameCropped '_avg_EPSC' '.txt'];
fileDestinationAvgEpsc=fullfile('txt_files', fileNameAvgEpsc);
%transpose matrix so it will play nice with Axograph
writematrix(avgEphysFileMatrix', fileDestinationAvgEpsc,...
            'Delimiter', 'tab');
%scaled EPSCs
fileNameScaledEpscs=[fileNameCropped '_scaled_EPSCs' '.txt'];
fileDestinationScaledEpscs=fullfile('txt_files', fileNameScaledEpscs);
%transpose matrix so it will play nice with Axograph
writematrix(epscsScaled', fileDestinationScaledEpscs,...
            'Delimiter', 'tab');

%%
%Calculate difference currents

%subtract average EPSC from each scaled EPSC
differenceCurrent=(epscsScaled(2:end,:)'-avgEphysFileMatrix(2,:)')';
differenceCurrent=[timeAxis; differenceCurrent];

figure
plot(differenceCurrent(1,:), differenceCurrent(2:end,:))
title('difference current, not cropped')
xlabel('ms')
ylabel('pA')

%crop difference current at peak of average EPSC
differenceCurrentCropped=differenceCurrent(:, peakAvgSweepIndex:end);

figure
plot(differenceCurrentCropped(1,:), differenceCurrentCropped(2:end,:))
title('difference current, cropped at peak')
xlabel('ms')
ylabel('pA')

%write difference currents as txt file
fileNameDifferenceCurrent=[fileNameCropped '_difference_currents' '.txt'];
fileDestinationDifferenceCurrent=fullfile('txt_files',...
                                 fileNameDifferenceCurrent);
%transpose matrix so it will play nice with Axograph
writematrix(differenceCurrentCropped', fileDestinationDifferenceCurrent,...
            'Delimiter', 'tab');

%%
%bin data based on fractional reduction of peak (defined by 'binSize')

%convert fraction binSize to pA value based on peak of average EPSC
binSizeCurrent=peakAvgSweep*-binSize;
%define the bins from 0 to peak avg epsc amplitude
binEdges=-(peakAvgSweep*binStart):binSizeCurrent:abs(peakAvgSweep);
binEdges=flip(binEdges)*-1; %flip to match sign of inward current

%crop average EPSC at peak
avgEpscCropped=avgEphysFileMatrix(2, peakAvgSweepIndex:end);
%assign bins to each point along average EPSC waveform
bins=discretize(avgEpscCropped, binEdges);
bins(isnan(bins))=(length(binEdges)-1);
%positive pA values after the current has decayed to baseline were not
%placed in a bin and given a value of NaN, this places all of those points
%into the last bin

%create array with bin assignments, average EPSC decay and difference
%currents
diffCurrentsBinned=[bins; avgEpscCropped;...
                    differenceCurrentCropped(2:end,:)];

%average columns in 'diffCurrentsBinned' that are within the same bin
for jj=1:length(binEdges)

    %index of the current bin, some bins are empty, row always=1
    [row, column]=find(diffCurrentsBinned==jj);

    %the first bin will always have at least 1 column, needs slightly
    %different scripting than later bins to assign values to correct column
    if jj==1
        if length(column)>1
            binData=diffCurrentsBinned(2:end,...
                                       column(1):column(length(column)));
        elseif length(column)==1
            binData=diffCurrentsBinned((2:end), column(1));
        end

        avgBin=sum(binData, 2)./length(column); %average columns in bin
        avgDiffCurrentsBins(:,1)=avgBin; %assign average value to first
                                         %column of new array

        clear binData avgBin

    %all other bins that contain data can be averaged and appended to the
    %array made after averaging the first bin
    elseif (jj>1) && (~isempty(column))
        if length(column)>1
            binData=diffCurrentsBinned(2:end,...
                                       column(1):column(length(column)));
        elseif length(column)==1
            binData=diffCurrentsBinned((2:end), column(1));
        end
        avgBin=sum(binData, 2)./length(column);
        nextColumn=size(avgDiffCurrentsBins, 2)+1;
        avgDiffCurrentsBins(:,nextColumn)=avgBin;

        clear binData avgBin
    end
end

%%
%Calculate sum square differences (variance) for each bin

sumSqDiff=avgDiffCurrentsBins(2:end,:).^2;
%calculate average SSD for each bin
avgSumSqDiff=sum(sumSqDiff, 1)./size(sumSqDiff, 1);
%flip sign of EPSC to make graph look better
avgEpscBinnedAvg=avgDiffCurrentsBins(1,:)*-1;
%place avg SSD and average EPSC into a single array
meanVariance(1,:)=avgEpscBinnedAvg;
meanVariance(2,:)=avgSumSqDiff;

figure
plot(meanVariance(1,:), meanVariance(2,:))
title('Mean Variance Plot')
xlabel('pA')
ylabel('Variance (pA^2)')

fileNameMeanVariance=[fileNameCropped '_mean_variance' '.txt'];
fileDestinationMeanVariance=fullfile('txt_files',...
                                 fileNameMeanVariance);
%transpose matrix so it will play nice with Axograph
writematrix(meanVariance', fileDestinationMeanVariance,...
            'Delimiter', 'tab');










            


       




































