function [assocs, overlap_start_end] = overlapping_segments(seg_list1, seg_list2, same_lists)
%OVERLAPPING_SEGMENTS Computes intersections of segments, returns non-empty pairs
%     [ASSOCS, OVERLAP_START_END] = OVERLAPPING_SEGMENTS(SEGS1, SEGS2)
%     find all pairs of segments that overlap.  ASSOCS contain the
%     respective indices into SEGS1 and SEGS2, while OVERLAP_START_END
%     denotes the range of the overlap.
%
%     [ASSOCS, OVERLAP_START_END] = OVERLAPPING_SEGMENTS(SEGS1, SEGS2, SAME_LISTS)
%     assumes that SEGS1 and SEGS2 are identical lists and only returns
%     unique overlaps (not every pair twice), and also does *not* return
%     overlaps of a segment with itself.

% Author: Makarand Tapaswi

if ~exist('same_lists', 'var')
    same_lists = false;
end

assocs = [];
overlap_start_end = [];

for ii = 1:size(seg_list1, 1)
    start = 1;
    if same_lists
        start = ii+1;
    end
    for jj = start:size(seg_list2, 1)
        seg1 = seg_list1(ii, :);
        seg2 = seg_list2(jj, :);
        
        start_seg = max(seg1(1), seg2(1));
        end_seg = min(seg1(2), seg2(2));
        if start_seg <= end_seg
            assocs = [assocs; [ii jj]];
            overlap_start_end = [overlap_start_end; [start_seg end_seg]];
        end
    end
end
