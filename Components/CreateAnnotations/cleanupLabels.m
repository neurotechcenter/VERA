function [electrodeDefinitionsOut] = cleanupLabels(electrodeDefinition,replaceLabels,labelRadius)
%CLEANUPLABELS removes 'Unknown' and adds the closest surface label to
%electrodes marked as cerebral cortex

if(length(replaceLabels) ~= length(labelRadius))
    error('Size of replaceLabels and labelRadius must be equal');
end
electrodeDefinitionsOut=(electrodeDefinition);
for i=1:length(electrodeDefinition.Label)
    
    for l=1:length(replaceLabels)
        [labels,removedLabel]=removeLabel(electrodeDefinitionsOut.Label{i},replaceLabels{l});
        electrodeDefinitionsOut.Label{i}=labels;
        curr_radius=labelRadius(l);
        if(any(removedLabel) || isempty(electrodeDefinitionsOut.Label{i}))
            [d,I]=sort(electrodeDefinitionsOut.Annotation(i).Distance);
            labels={electrodeDefinitionsOut.Annotation(i).Label{I}};
            for ll=1:length(replaceLabels)
                [labels,removedLabel]=removeLabel(labels,replaceLabels{ll});
                
                if(any(removedLabel) && any(d(removedLabel) < labelRadius(ll)))
                    curr_radius=curr_radius+max(d(removedLabel));
                end
                d=d(~removedLabel);
            end
            [labels,removedLabel]=removeLabel(labels,'Unknown');
            d=d(~removedLabel);
            if(any(d <= curr_radius))
                electrodeDefinitionsOut.Label{i}=labels(1);
            else %keep original label
                electrodeDefinitionsOut.Label{i}=electrodeDefinition.Label{i};
            end
            
        end
    end
    
    
end

end




function [labels,labelIds]=removeLabel(labels,toRemove)
    labelIds=strcmp(labels,toRemove);
    if(any(labelIds))
        labels=labels(~labelIds);
    end
end