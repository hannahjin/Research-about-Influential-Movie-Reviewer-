%unique_users = unique(m(:,2));

helpfulness = m(:,3)./m(:,4) ;
idx = m(:,4) >= 30 & ( helpfulness >= 0.5);
special_users = unique(m(idx,2));
special_ustats = zeros(length(special_users), 3);
for i=1:length(special_users);
    user_id = special_users(i);
    ind = m(:,2) == user_id;
    ind2 = m(:,2) == user_id & m(:,4) > 3;
    special_ustats(i,1) = sum(ind);
    special_ustats(i,2) = mean(m(ind, 5));
    hlpn = m(ind2,3)./m(ind2,4);
    special_ustats(i,3) = mean(hlpn);
end

u = special_ustats(:,1) >= 7000;

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
for k = 1:length(chosen)
    uid = chosen(k);
    overlap = zeros(length(unique_users),1);
    score_diff = zeros(length(unique_users),1);
    avg_hlpn = user_stats(:,3);
    for i = 1:length(unique_users)
        regid = unique_users(i);
        uin = m(:,2) == regid;
        cin = m(:,2) == uid;
        index1 = intersect(m(uin, 1),m(cin,1));
        overlap(i) = length(index1);
        score_diff(i) = abs(chosen_stats(k,2) - user_stats(i,2));
    end
    h = figure(10); clf;
    plot(overlap(overlap ~= chosen_stats(k,1)),score_diff, 'or');
    xlabel('# same movie');
    ylabel('avg score diff');
    saveas(h, sprintf('average score diff vs. overlap.%d.png', uid));
    h = figure(20); clf;
    plot(overlap(overlap~=chosen_stats(k,1)),avg_hlpn, 'ob');
    xlabel('# same movie');
    ylabel('average helpfulness');
    saveas(h, sprintf('avg helpfulness vs. overlap.%d.png', uid));
    
    
    % CLUSTERING
    num_clusters = 4;
    OL = overlap(overlap < chosen_stats(k,1));
    SD = score_diff(overlap < chosen_stats(k,1));
    X = [OL SD];
    opts = statset('Display','final');
    [idx, ctrs] = kmeans(X, num_clusters, 'Distance', 'city', 'REplicates', 5, 'Options', opts);
    h = figure(30); clf;
    styles = {'ob', 'og', 'or', 'om', 'ok'};
    for inc=1:num_clusters
        plot(OL(idx==inc), SD(idx==inc), styles{inc});
        hold on;
    end
%     num_clusters = 4;
%     OL = overlap(overlap < chosen_stats(3,1));
%     SD = score_diff(overlap < chosen_stats(3,1));
%     X = [OL SD];
%     opts = statset('Display','final');
%     [idx, ctrs] = kmeans(X, num_clusters, 'Distance', 'city', 'REplicates', 5, 'Options', opts);
%     h = figure(21); clf;
%     styles = {'ob', 'og', 'or', 'om', 'ok'};
%     for inc=1:num_clusters
%         plot(OL(idx==inc), SD(idx==inc), styles{inc});
%         hold on;
%     end

%     % LINEAR REGRESSION
%     p = polyfit(J, SD, 1);
%     a = axis;
%     x = linspace(a(1), a(2), 100);
%     y = p(1).*x + p(2);
%     plot(x, y, '-k');
%     corr(J, SD)^2
    
    p = polyfit(OL, SD, 1);
    a = axis;
    x = linspace(a(1), a(2), 100);
    y = p(1).*x + p(2);
    plot(x, y, '-k');
    saveas(h, sprintf('scorediff vs. overlap.cluster.%d.png', uid));
    corr(OL, SD)^2
    
    

end

% unique_movies = unique(m(:,1));
% col#1: review count for each user
% col#2: average score
% col#3: average helpfulness
% col#4: average helpfulness with 5 or more feedbacks
% col#4: jaccard value with respect to chosen user

special_ustats = zeros(length(unique_users), 4);
for i=1:length(unique_users)
    user_id = unique_users(i);
    me = m(:,2) == user_id;
    ui = me & m(:,4) >= 20;
    special_ustats(i,1) = sum(me); % review count
    special_ustats(i,2) = mean(m(me,5)); % average score
    special_ustats(i,3) = mean(m(me, 3)./m(me, 4)); % avg_help 1
    special_ustats(i,4) = mean(m(ui, 3)./m(ui, 4)); % avg_help 2
    special_ustats(i,5) = sum(m(me, 4));
end