clear
close all
clc

SubjName = 'Mas';
NumSession = 2;

% 1-8
% 9-11
% 12-13

C = 10;
for iSubject = 0 : NumSession
    
    load(['Behavioral_Exp_Subject_' SubjName num2str(iSubject,'%0.4d') '.mat'])
    response_Matrix = stimLists.Response;
    orientation_Step_Array = unique(round(C*stimLists.Response(5,:)));
    index_Trial_Type = unique( response_Matrix(end,:) );
    for iTrial_Type = 1 : length(index_Trial_Type)
        
        this_Trial_Response_Matrix = response_Matrix(:, response_Matrix(end, :)==index_Trial_Type(iTrial_Type));
        
        for iOrientation_Step = 1 : length(orientation_Step_Array)
            
            subject_Performance{iTrial_Type}(1,iOrientation_Step, iSubject+1) = median(this_Trial_Response_Matrix(1, round(C*this_Trial_Response_Matrix(5,:))==orientation_Step_Array(iOrientation_Step))) ; % RT
            subject_Performance{iTrial_Type}(2,iOrientation_Step, iSubject+1) = mean(this_Trial_Response_Matrix(2, round(C*this_Trial_Response_Matrix(5,:))==orientation_Step_Array(iOrientation_Step))) ; % Perf
            
        end
        
    end
    
    
    
end


Color = [0 0 0;1 0 0;0 1 0;0 0 1];

for iTrial_Type = 1 : length(index_Trial_Type)
    
    if iTrial_Type <= 2
        subplot(2,2,1)
    else
        subplot(2,2,2)
    end
    
    mean_RT = mean(subject_Performance{iTrial_Type}(1,:,:), 3);
    error_RT = std(subject_Performance{iTrial_Type}(1,:,:), [], 3)/sqrt(size(subject_Performance{iTrial_Type}(1,:,:), 3));
    h = errorbar([fliplr(-stim.TestOriDiff) stim.TestOriDiff],...
        mean_RT, error_RT, '-o');
    h.Color = Color(iTrial_Type,:);
    h.MarkerEdgeColor = Color(iTrial_Type,:);
    h.MarkerFaceColor = 'w';
    
    hold on

    
    if iTrial_Type==2
        legend('','discrimination','','adaptation', 'location', 'best')
    elseif iTrial_Type==4
        legend('','early','','late', 'location', 'best')
    end
    
    xlabel('\Delta Ori')
    ylabel('RT (ms)')
    
end


for iTrial_Type = 1 : length(index_Trial_Type)
    
    if iTrial_Type<=2
        subplot(2,2,3)
    else
        subplot(2,2,4)
    end
    
%     plot(fliplr(-stim.TestOriDiff), 1-Perf{iTrial_Type}(2,1:length(stim.TestOriDiff)), '-o', 'color', Color(iTrial_Type,:)), hold on
%     plot(stim.TestOriDiff, Perf{iTrial_Type}(2, length(stim.TestOriDiff)+1:end), '-o', 'color', Color(iTrial_Type,:)), hold on
    
    mean_Accuracy = [mean(1-subject_Performance{iTrial_Type}(2, 1:length(stim.TestOriDiff),:), 3),...
        mean(subject_Performance{iTrial_Type}(2, length(stim.TestOriDiff)+1:end, :), 3)];
        
    error_Accuracy = [std(subject_Performance{iTrial_Type}(2, 1:length(stim.TestOriDiff),:), [], 3),...
        std(subject_Performance{iTrial_Type}(2, length(stim.TestOriDiff)+1:end, :), [], 3)]./sqrt(size(subject_Performance{iTrial_Type}(1,:,:), 3));
    
    
    h = errorbar([fliplr(-stim.TestOriDiff) stim.TestOriDiff],...
        mean_Accuracy, error_Accuracy, '-o');
    h.Color = Color(iTrial_Type,:);
    h.MarkerEdgeColor = Color(iTrial_Type,:);
    h.MarkerFaceColor = 'w';
    
    hold on
    
    if iTrial_Type==2
        legend('discrimination','adaptation', 'location', 'best')
    elseif iTrial_Type==4
        legend('early','late', 'location', 'best')
    end
    
%     plot([fliplr(-stim.TestOriDiff) stim.TestOriDiff], 0.5*ones(2*size(stim.TestOriDiff)), ':k')
%     plot([0 0], [0 1], ':k')
    xlabel('\Delta Ori')
    ylabel('Response')
end