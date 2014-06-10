unique_users = unique(m(:,2));
user_stats = zeros(length(unique_users), 4);
for i=1:length(unique_users)
    user_id = unique_users(i);
    me = m(:,2) == user_id;
    ui = m(:,2) == user_id & m(:,4) >= 5;
    
    user_stats(i,1) = sum(me); % review count
    user_stats(i,2) = mean(m(me,5)); % average score
    hlp = m(ui,3)./m(ui,4);
    if ( ~isempty(hlp) )
        user_stats(i,3) = sum(hlp)/length(hlp); % avg_help
    
    else 
        user_stats(i,3) = 0;
    end
    au = m(me,4) > 0;
    user_stats(i,4) = sum(au);% # reviews with rating
end

pop = user_stats(:,4)./user_stats(:,1);
u = pop > 0.95 & user_stats(3) > 0.9;

chosen = unique_users(u);
chosen_stats = user_stats(u,:);
for iu = 1:length(chosen)
    uid = chosen(iu);
    IND = m(:,2) == uid;
    jaccard = zeros(length(unique_users),1);
    score_diff = zeros(length(unique_users),1);
    for i = 1:length(unique_users)
         user_id = unique_users(i);
         ind = m(:,2) == user_id;
         jaccard(i) = length(intersect(m(IND, 1), m(ind, 1)))/length(union(m(IND, 1), m(ind, 1)));
         score_diff(i) = abs(chosen_stats(iu, 2) - user_stats(i, 2));
    end

     % CLUSTERING
    num_clusters = 3;
    J = jaccard(0 < jaccard & jaccard < 1);
    SD = score_diff(0 < jaccard & jaccard < 1);
    X = [J SD];
    opts = statset('Display','final');
    [idx, ctrs] = kmeans(X, num_clusters, 'Distance', 'city', 'REplicates', 5, 'Options', opts);
    h = figure(21); clf;
    styles = {'ob', 'og', 'or', 'om', 'ok'};
    for inc=1:num_clusters
        plot(J(idx==inc), SD(idx==inc), styles{inc});
        hold on;
    end


    % LINEAR REGRESSION
    p = polyfit(J, SD, 1);
    a = axis;
    x = linspace(a(1), a(2), 100);
    y = p(1).*x + p(2);
    plot(x, y, '-k');
    corr(J, SD)^2

    xlabel('Jaccard Index');
    ylabel('Score Difference');
    title(sprintf('score_diff vs jaccard-%d', uid));
    saveas(h, sprintf('score_diff vs jaccard-%d.png', uid));

end

% Correlation
% 371 =
% 
%     0.0027
% 
% 644 =
% 
%     0.0084
% 
% 2753 =
% 
%    2.0733e-04
% 
% 3008 =
% 
%     0.0152
% 
% 3297 =
% 
%     0.0209
%
% 8188 =
% 
%     0.0175
%
% 19306 =
% 
%     0.0190
% 
% 43949 =
% 
%     0.0149