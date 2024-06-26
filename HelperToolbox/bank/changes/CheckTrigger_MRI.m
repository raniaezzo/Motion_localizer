function [kb,stop] = CheckResponseButton_MRI(kb,triggerStart)

% poll the response button (MRI) for a response
stop = 0;


[~, kb.secs, kb.keyCode] = KbCheck(-1); % for checking escape %(kb.ID)

% check the response button
% % scanner
Datapixx('RegWrRd');
kbchk = dec2bin(Datapixx('GetDinValues'));
% [kbchk(14) triggerStart(14)]
if kbchk(14) ~= triggerStart(14)          
    kb.resp = 5;
    kb.keyIsDown = 1;

elseif kb.keyCode(kb.escKey) || kb.keyCode(kb.qKey) % esc/q key, quit
    stop =1;
end
% 
% %pc
% if kbchk(16) == '1' % or towards / near - blue button
%     kb.resp = 2;
%     kb.keyIsDown = 1;
% elseif kbchk(17) == '1' %  - green button
%     kb.resp = 2;
%     kb.keyIsDown = 1;
% elseif kbchk(18) == '1' % or away/far - yellow button
%     kb.resp = 1;
%     kb.keyIsDown = 1;
% elseif kbchk(19) == '1' % - red button
%     kb.resp = 1;
%     kb.keyIsDown = 1;
% elseif kb.keyCode(kb.escKey) || kb.keyCode(kb.qKey) % esc/q key, quit
%     stop =1;
% else
% end
end