function [events, blinkSignal] = ...
           getBlinkEvents(blinks, blinkFits, blinkProperties, fieldList)
%% Create an events structure with a standard set of blink events
%
%  Parameters:
%      blinks            structure produced
%      blinkFits         structure produced by the BLINKER software
%      blinkProperties   structure produced by the BLINKER software
%      fieldList         cell array with blinkFit field names of events
%      events            (output) structure with type, latency, duration, 
%                        usertags, and hedtags fields
%      blinkSignal       (output) signals
%
%  Written by:  Kay Robbins, UTSA, 2017
%
%% Initialize the 
    blinkSignal = [];
    if isempty(blinkFits)
        events = struct();
        warning('insertBlinkEvents:NoBlinks', 'Dataset has no blinks');
        return;
    end
   
%% Valid fields to use for events
    validEvents = getValidEvents();
    validFields = {validEvents.fieldName};
    [usedFields, vMask] = intersect(validFields, fieldList);
    if isempty(usedFields)
        warning('insertBlinkEvents:NoValidFields', 'Field values are not invalid');
        return;
    end
    usedEvents = validEvents(vMask);
    badFields = setdiff(fieldList, validFields);
    if ~isempty(badFields)
       badFieldString = badFields{1};
       for k = 1:length(badFields)
           badFieldString = [badFieldString ',' badFields{k}]; %#ok<AGROW>
       end
       warning('insertBlinkEvents:SkippingFields', 'Invalid fields %s', badFieldString);
    end

%% Get preliminary number of blinks and create an events structure
    numBlinks = length(blinkFits);
    numEvents = length(usedEvents)*numBlinks;
    events(numEvents) = struct('type', NaN, 'latency', NaN, ...
        'duration', NaN, 'usertags', NaN,  'hedtags', NaN);

    pos = 0; 
    for n = 1:length(usedEvents)
        theLatencies = cellfun(@double, {blinkFits.(usedFields{n})});
        userTags = ['/Event/Category/Incidental,' ...
            '/Event/Label/' usedEvents(n).label ',' ...
            '/Event/Long name/' usedEvents(n).longName ',' ...
            '/Event/Description/' usedEvents(n).description ',' ...
            usedEvents(n).userTags];

        for k = 1:numBlinks
            pos = pos + 1;
            events(pos) = events(numEvents);
            events(pos).type = usedEvents(n).fieldName;
            events(pos).latency = theLatencies(k);
            events(pos).duration = 0;
            events(pos).usertags = userTags;
            events(pos).hedtags = ...
                ['/Attribute/Blink/Duration/' ...
                num2str(blinkProperties(k).durationHalfZero) ' s,' ...
                '/Attribute/Blink/PAVR/' ...
                num2str(blinkProperties(k).posAmpVelRatioBase) ' cs,' ...
                '/Attribute/Blink/NAVR/' ...
                num2str(blinkProperties(k).negAmpVelRatioBase) ' cs'];
        end
    end
    
    %% Now construct the zeroed signal
    if isempty(blinks) || ~isfield(blinks, 'signalData') || isempty(blinks.signalData)
        warning('getBlinkEvents:NoBlinkSignal', 'blinks did not have signal data');
        return;
    end
    signal = blinks.signalData.signal;
    blinkSignal = zeros(size(signal));
    startZeros = cellfun(@double, {blinkFits.leftZero});
    endZeros = cellfun(@double, {blinkFits.rightZero});
    for k = 1:numBlinks
        blinkSignal(startZeros(k):endZeros(k)) = signal(startZeros(k):endZeros(k));
    end
    blinkSignal(blinkSignal < 0) = 0;
    %% Construct the valid events
    function validEvents = getValidEvents()
        validEvents(3) = struct('fieldName', NaN, 'label', NaN, ...
                         'longName', NaN, 'description', NaN, 'userTags', NaN);

        validEvents(1).fieldName = 'maxFrame';
        validEvents(1).label = 'BlinkMax';
        validEvents(1).longName = 'Time of maximum blink amplitude';
        validEvents(1).description = 'Time blink signal first reaches maximum';
        validEvents(1).userTags = '/Action/EyeBlink/Max';
        validEvents(2).fieldName = 'leftZero';
        validEvents(2).label = 'BlinkLeftZero';
        validEvents(2).longName = 'Blink first crosses zero on close';
        validEvents(2).description = 'Time blink signal first crosses zero on close';
        validEvents(2).userTags = '/Action/EyeBlink';
        validEvents(3).fieldName = 'rightZero';
        validEvents(3).label = 'BlinkRightZero';
        validEvents(3).longName = 'Time blink signal first crosses zero on open';
        validEvents(3).description =  'Time blink signal first crosses zero on open';
        validEvents(3).userTags = '/Action/EyeBlink';
        validEvents(4).fieldName = 'leftBase';
        validEvents(4).label = 'BlinkLeftBase';
        validEvents(4).longName = 'Time blink signal local minimum on close';
        validEvents(4).description =  'Time blink signal local minimum on close';
        validEvents(4).userTags = '/Action/EyeBlink';
        validEvents(5).fieldName = 'rightBase';
        validEvents(5).label = 'BlinkRightBase';
        validEvents(5).longName = 'Time blink signal crosses low on open';
        validEvents(5).description =  'Time blink signal first crosses local minimum on open';
        validEvents(5).userTags = '/Action/EyeBlink';
        validEvents(6).fieldName = 'leftZeroHalfHeight';
        validEvents(6).label = 'BlinkLeftZeroHalf';
        validEvents(6).longName = 'Time blink signal reaches zero half height on close';
        validEvents(6).description =  'Time blink signal reaches zero half height on close';
        validEvents(6).userTags = '/Action/EyeBlink';
        validEvents(7).fieldName = 'rightZeroHalfHeight';
        validEvents(7).label = 'BlinkRightHalfZero';
        validEvents(7).longName = 'Time blink signal reaches zero half height on open';
        validEvents(7).description =  'Time blink signal reaches zero half height on open';
        validEvents(7).userTags = '/Action/EyeBlink';
   

        %         validFields = {'maxFrame', 'leftOuter', 'rightOuter', ...
        %                'leftZero', 'rightZero', 'leftBase', 'rightBase', ...
        %                'leftBaseHalfHeight', 'rightBaseHalfHeight', ...
        %                'leftZeroHalfHeight', 'rightZeroHalfHeight'};

    end
end