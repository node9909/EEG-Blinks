%% Setup
correlationThresholdTop = 0.98;
correlationThresholdBottom = 0.90; 
correlationThresholdMiddle = 0.95;
dumpWeb = true;
maxAmp = 600;
%% BCIT Examples
experiment = 'BCITLevel0';
blinkDir = 'O:\ARL_Data\BCITBlinks';
type = 'EOGUnrefNew';

%% Shooter Examples
% experiment = 'Shooter';
% blinkDir = 'O:\ARL_Data\Shooter\ShooterBlinks';
% type = 'EOGUnref';
% type = 'ChannelUnref';

%% NCTU blinks
% blinkDir = 'O:\ARL_Data\NCTU\NCTU_Blinks';
% experiment = 'NCTU_LK';
% type = 'Channel';

%% BCI2000 blinks
% type = 'Channel';
% experiment = 'BCI2000';
% blinkDir = 'O:\ARL_Data\BCI2000\BCI2000Blinks';

%% DREAMS
% type = 'EOGMast';
% experiment = 'Dreams';
% blinkDir = 'E:\CTADATA\WholeNightDreams\data\blinks';

%% Read in the blink data for this collection
% blinkFile = [experiment 'BlinksNew' type '.mat'];
% blinkPropertiesFile = [experiment 'BlinksNewProperties' type '.mat'];
% load([blinkDir filesep blinkFile]);
% load([blinkDir filesep blinkPropertiesFile]);

%% Open the index file
indexFile = [experiment type 'maxFrameDist.html'];
if dumpWeb
    fid = fopen(indexFile, 'w'); 
else
    fid = 1; %#ok<UNRCH>
end
fprintf(fid, '<h1>Experiment %s Type %s</h1>\n', experiment, type);
fprintf(fid, '<p>Top correlation: %d   Bottom correlation: %d</p>\n', ...
        correlationThresholdTop, correlationThresholdBottom);
%% Process the data
for k = 1:length(blinks)
    if isnan(blinks(k).usedSignal)
        fprintf(fid, '<p>%d: %s has no blinks</p>\n', k, blinks(k).fileName);
        continue;
    end
%% test the threshold
   dFits = blinkFits{k};
   maxValues = {dFits.maxValue};
   indicesNaN = cellfun(@isnan, maxValues);
   goodMask = getGoodBlinkMask(dFits, correlationThresholdBottom);
   goodValues = maxValues(~indicesNaN & goodMask);
   allValues = maxValues(~indicesNaN);
   goodValues = cellfun(@double, goodValues);
   allValues = cellfun(@double, allValues);
   
%% Now compute the histograms
   nbins = max(20, sqrt(length(allValues)));
   xmin = min(allValues);
   xmax = prctile(allValues, 98);
   
   xhist = linspace(xmin, xmax, nbins);
   [n1, x1] = hist(allValues, xhist);
   [n2, x2] = hist(goodValues, xhist);
   
   theTitle = {[num2str(k) ': ' blinks(k).uniqueName ' ' blinks(k).type]; ...
       ['All:' num2str(length(allValues)) ...
       '  Good:' num2str(length(goodValues))]};             
   h = figure('Color', [1, 1, 1], 'Name', theTitle{1});
   hold on
 
   plot(x1, n1, 'Color', [1, 0, 0], 'LineWidth', 2)
   plot(x2, n2, 'Color', [0.3, 1, 0.3], 'LineWidth', 2, 'LineStyle', '--')
   legend( 'All', 'Good');
   
   xlabel('Blink max amplitude')
   ylabel('Count')
   hold off
   title(theTitle, 'Interpreter', 'None');
   box on
   [thePath, theName, theExt] = fileparts(blinks(k).fileName);
   
   if dumpWeb
      fileName = [theName '.png'];
      saveas(gcf, fileName, 'png');
      fprintf(fid, '<p><img src=''%s''  alt=''%s''/></p>\n', fileName, theName);
   else
      fileName = [theName '.fig'];
      saveas(gcf, fileName, 'fig');
   end
   
   close(gcf);
end  
fclose(fid);
fprintf('Number of split files %d\n', splitCount);