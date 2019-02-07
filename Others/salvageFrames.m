function [ex]=salvageFrames(ex)
%utility function to correct the white noise stimulus sequence for dropped 
%frames
% we make the following assumptions:
% 1) we assume inter-frame-intervals >1.5*1/refreshRate correspond to dropped
% frames
% 2) the previous screen just stayed on, i.e. the stimulus didn't change
% when a frame was dropped, and the added frame duration was 1/refreshRate
% 
% We will therefore correct:
%   -ex.Trials(n).Start :   to include the "start" of the dropped frame. It
%                           will start 1/refreshRate after the preceding
%                           fram
%                           
%   -ex.Trials(n).hdx_seq: we will insert the values of the stimuli that
%                          stayed on for an additional frame
%   -ex.Trials(n).framecnt (to match length of ex.Trials(n).Start)
%
% history
% 04/06/17  hn: wrote it


frame_dur = 1/ex.setup.refreshRate;

for n=1:length(ex.Trials)
    
    durs = diff([ex.Trials(n).Start]);
    idx = find(durs>=1.5*frame_dur);
    
    % loop through all the dropped frames and insert an additional one that
    % is identical to the preceding frame
    st = ex.Trials(n).Start;
    if size(st,1) > 1
            st = st';
    end
    framecnt = ex.Trials(n).framecnt;
    hs = ex.Trials(n).hdx_seq;
    for nf = 1:length(idx)
        st = [st(1:idx(nf)), st(idx(nf))+frame_dur, ...
            st(idx(nf)+1:end)];
        hs = [hs(1:idx(nf)), hs(idx(nf)), ...
            hs(idx(nf)+1:end)];
        framecnt = framecnt+1;
        idx =idx+1; % to account for the insertion of another frame
    end
    ex.Trials(n).framecnt= framecnt;
    ex.Trials(n).Start = st;
    ex.Trials(n).hdx_seq = hs(1:framecnt);  % adjust length to actually presented frames
end