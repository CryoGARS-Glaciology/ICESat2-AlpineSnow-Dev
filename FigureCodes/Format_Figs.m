%% Set parameters on figures
%%%     

%% loop through many figures
num_figs = 3; %largest figure number of open figures

for i = 1:num_figs
    figure(i);
    set(findall(gcf,'-property','FontSize'),'FontSize',20)
end

%% edit current figure







