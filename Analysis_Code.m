clear
close all
clc

SubjName = 'Mas';
NumSession = 14;

% 1-8
% 9-11
% 12-13
AllRe = [];
for s = 12 : NumSession
    
    load(['Behavioral_Exp_Subject_' SubjName num2str(s,'%0.4d') '.mat'])
    AllRe = [AllRe stimLists.Response];
    
end

Cof = 10;
Color = [0 0 0;1 0 0;0 1 0;0 0 1];
Ind = unique( AllRe(end,:) );
for i = 1 : length(Ind)
    
    Resp{i} = AllRe(:, AllRe(end, :)==Ind(i));
    
end


OriSiz = unique(round(Cof*stimLists.Response(5,:)));
for j = 1 : length(Ind)
    for i = 1 : length(OriSiz)
        
        Perf{j}(1,i) = median(Resp{j}(1, round(Cof*Resp{j}(5,:))==OriSiz(i))) ; % RT
        Perf{j}(2,i) = mean(Resp{j}(2, round(Cof*Resp{j}(5,:))==OriSiz(i))) ; % Perf
        
    end
end

for j = 1 : length(Ind)
    
    if j<=2
        subplot(2,2,1)
    else
        subplot(2,2,2)
    end
    plot(fliplr(-stim.TestOriDiff), Perf{j}(1,1:length(stim.TestOriDiff)), '-o', 'color', Color(j,:)), hold on
    plot(stim.TestOriDiff, Perf{j}(1, length(stim.TestOriDiff)+1:end), '-o', 'color', Color(j,:)), hold on
    
    if j==2
        legend('','discrimination','','adaptation')
    elseif j==4
        legend('','early','','late')
    end
    xlabel('\Delta Ori')
    ylabel('RT (ms)')
    
end


for j = 1 : length(Ind)
    
    if j<=2
        subplot(2,2,3)
    else
        subplot(2,2,4)
    end
    
    plot(fliplr(-stim.TestOriDiff), 1-Perf{j}(2,1:length(stim.TestOriDiff)), '-o', 'color', Color(j,:)), hold on
    plot(stim.TestOriDiff, Perf{j}(2, length(stim.TestOriDiff)+1:end), '-o', 'color', Color(j,:)), hold on
    if j==2
        legend('','discrimination','','adaptation')
    elseif j==4
        legend('','early','','late')
    end
    xlabel('\Delta Ori')
    ylabel('Response')
end