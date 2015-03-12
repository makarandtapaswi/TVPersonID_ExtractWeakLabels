function ST = split_subtitle_lines(TextStruct)
% SPLIT_SUBTITLE_LINES Splits the output of the subtt-trans matcher across lines
% 
% Example usage:
% TextStruct = subtitle_transcript_matcher(VideoStruct, params)
% ST = split_subtitle_lines(TextStruct)
% 
% Author: Makarand Tapaswi
% Last modified: 02-10-2012

ST = struct; 
cnt = 1; oldcnt = 1;
for k = 1:length(TextStruct)
    num_lines = TextStruct(k).lcount;
    for ii = 1:num_lines
        % Generate new idx (now formatted like the labels -> 3.1, 3.2, 4.1, 5.1
        ST(cnt).idx = TextStruct(k).idx + ii/10;
        
        % Split lines
        ST(cnt).line = TextStruct(k).line{ii};
        ST(cnt).lcount = 1;
        ST(cnt).charcount = length(ST(cnt).line);
        ST(cnt).VoiceOver = 0;
        ST(cnt).ErrorRate = [];
        ST(cnt).TransStructIdx = [];
        ST(cnt).IdxDtwMatchType = [];

        % split speakers gt, and tagged
        if isfield(TextStruct(k), 'groundTruthIdentity') && ~isempty(TextStruct(k).groundTruthIdentity)
            ST(cnt).groundTruthIdentity = TextStruct(k).groundTruthIdentity{ii};
        end
        
        try
            ST(cnt).Speaker = TextStruct(k).Speaker{ii};
            try ST(cnt).VoiceOver = TextStruct(k).VoiceOver{ii}; end

            % split info from subtt-trans matcher
            try ST(cnt).ErrorRate = TextStruct(k).ErrorRate(ii); end
            try ST(cnt).TransStructIdx = TextStruct(k).TransStructIdx{ii}; end
            try ST(cnt).IdxDtwMatchType = TextStruct(k).IdxDtwMatchType{ii}; end
        catch
            % comes here basically if the above is not a cell, OR
            % is empty, so was not intialized as a cell, OR
            % is populated with only first line, since second line is empty
            %fprintf('no speaker name for %d -- %d\n', k, cnt);
            ST(cnt).Speaker = '';
            ST(cnt).ErrorRate = [];
            ST(cnt).TransStructIdx = [];
            ST(cnt).IdxDtwMatchType = [];
        end        
        cnt = cnt + 1;
    end
    
    if num_lines > 1
        chars_per_line = [ST(oldcnt:(cnt-1)).charcount];
        duration = TextStruct(k).endtime - TextStruct(k).starttime;
        % handle a special case of a subtitle like this: from got_s01e01
%         62
%         00:10:08,560 --> 00:10:10,599
%          - (Sighs)
%          - (Laughing)
        if sum(chars_per_line) == 0
            timings = TextStruct(k).starttime + [0, duration/2, duration];
        else
            timings = TextStruct(k).starttime + cumsum([0, duration*chars_per_line/sum(chars_per_line)]);
        end

        % assign the timings vector index 1-2-3 as 1-2, and 2-3 (when 2 lines)
        for ii = oldcnt:(cnt-1)
            ST(ii).starttime = timings(ii-oldcnt+1);
            ST(ii).endtime = timings(ii+1-oldcnt+1);
        end
    else
        ST(oldcnt).starttime = TextStruct(k).starttime;
        ST(oldcnt).endtime = TextStruct(k).endtime;
    end    
    oldcnt = cnt;
end
