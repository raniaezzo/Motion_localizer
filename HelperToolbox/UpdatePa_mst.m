function pa = UpdatePa_mst(VP,pa,whichLoc)

% 10/25/2022 less dots, no fixation during stimulus, check disparity

rng('shuffle'); % shuffle the random number generator seeds so you don't repeat!
%rng('default');
%% Stimulus Parameters
% These are the locations of the stimuli
if strcmp(whichLoc, 'mstL') 
    thetas = 0;
elseif strcmp(whichLoc, 'mstR')
    thetas = 180;                                                                 % Polar angle(s) of stimulus
end

pa.thetaDirs = thetas;                                                           % Polar angle(s) of circle
pa.rDirs = 8.5;                                                              % Eccentricity of circle
radius_stim = 8.5;                                                            % Eccentricity of stimulus
pa.stimX_deg = radius_stim*cosd(thetas);                                 
pa.stimY_deg = radius_stim*sind(thetas);
pa.screenAperture = 30; %24.5    %30                                          % stimulus size radius
pa.borderPatch = 30.2; % 25;      %30.2                                        % aperture size radius
pa.centerPatch = 9.8; %15.5;   %9.8  %15.5;                          % fixation aperture size radius
pa.numberOfDots = 200;                                                      % number of dots

pa.coherence = 1;                                                          % Motion coherence levels
pa.conditionNames   = {'cd4','cd0'};   %'circular'      % Stimulus conditions

[pTH,pR] = cart2pol(pa.stimX_deg, pa.stimY_deg);
pTH = -rad2deg(pTH);
if pTH < 0
    pTH = 360 + pTH;
end
pa.allPositions = [pTH; pR]';

% MST params

pa.phi = 2*pi*rand(1,pa.numberOfDots); % random phi

if strcmp(pa.conditionNames{1}, 'circular')
    pa.tf = 1.5;
    rmin = tand(pa.centerPatch*1.05)*VP.screenDistance;
    rmax = tand(pa.borderPatch*0.95)*VP.screenDistance;
else
    rmin = tand(pa.centerPatch*1.05)*VP.screenDistance+pa.amp;
    rmax = tand(pa.borderPatch*0.95)*VP.screenDistance-pa.amp;
end
aa=[0 180];
pa.theta = (aa(~ismember(aa,thetas))-60+120*rand(1,pa.numberOfDots))/180*pi;
pa.theta(pa.theta>pi) = pa.theta(pa.theta>pi)-2*pi;
pa.r = (((rmax - rmin) .* (sqrt(rand(1,pa.numberOfDots)))) + rmin)';
pa.phi = 2*pi*rand(1,pa.numberOfDots);


end






