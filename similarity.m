%m = csvread('reviews.csv');
%m = csvread('reviews.csv', 0, 0, [0,0,1000000,5]);

figure(1);
hist(m(:,4));
xlabel('# of feedbacks');
ylabel('# of reviews');
title('Helpfulness Feedback # Distribution');

figure(2);
r1 = m(:,4) <= 10000;
hist(m(r1,4), 18);
xlabel('# of feedbacks');
ylabel('# of reviews');
title('Helpfulness Feedback # Distribution <=10,000');
set(gca, 'yscale', 'log');

figure(3);
r2 = m(:,4) > 10000;
hist(m(r2,4));
xlabel('# of feedbacks');
ylabel('# of reviews');
title('Helpfulness Feedback # Distribution >10,000');

unique_users = unique(m(:,2));
unique_movies = unique(m(:,1));
% col#1: review count for each user
% col#2: average score
% col#3: average helpfulness
% col#4: average helpfulness with 5 or more feedbacks
% col#4: jaccard value with respect to chosen user
user_stats = zeros(length(unique_users), 5);
for i=1:length(unique_users)
    user_id = unique_users(i);
    u_ind = m(:,2) == user_id;
    u_ind2 = u_ind & m(:,4) >= 6;
    user_stats(i,1) = sum(u_ind); % review count
    user_stats(i,2) = mean(m(u_ind,5)); % average score
    user_stats(i,3) = mean(m(u_ind, 3)./m(u_ind, 4)); % avg_help 1
    user_stats(i,4) = mean(m(u_ind2, 3)./m(u_ind2, 4)); % avg_help 2
    user_stats(i,5) = sum(m(u_ind, 4));
end

figure(5);
hist(user_stats(:,1));
xlabel('# of reviews');
ylabel('# of users');
title('user_review_count');

figure(6);
hist(user_stats(:,1));
xlabel('# of reviews');
ylabel('# of users');
title('user_review_count-logscale');
set(gca, 'yscale', 'log');

figure(7);
hist(user_stats(:,2), 1:.5:5);
xlabel('avg_score');
ylabel('# of users');
title('user_avg_score');

h = figure(99); clf;
ind = user_stats(:,1) < 100;
plot(user_stats(ind,1), user_stats(ind,5),'ob');
hold on;
p = polyfit(user_stats(ind, 1), user_stats(ind,5), 1);
a = axis;
x = linspace(a(1), a(2), 100);
y = p(1)*x + p(2);
plot(x, y, '-k');
xlabel('# Reviews');
ylabel('# of People who gave feedback');
c99 = corr(user_stats(ind,1), user_stats(ind,5))^2;
saveas(h, '#reviews vs. # feedbacks.png');

h = figure(98); clf;
ind = user_stats(:,1) < 100;
plot(user_stats(ind,1), user_stats(ind,2),'ob');
hold on;
p = polyfit(user_stats(ind, 1), user_stats(ind,2), 1);
a = axis;
x = linspace(a(1), a(2), 100);
y = p(1)*x + p(2);
plot(x, y, '-k');
xlabel('# Reviews');
ylabel('Avg. Score');
c98 = corr(user_stats(ind,1), user_stats(ind,2))^2;
saveas(h, '#reviews vs. avg. score.png');


h = figure(97);
bins = 0:25:400;
subplot(2,1,1);
ind = user_stats(:,1) < 5;
hist(user_stats(ind, 5), bins);
title('Users with < 5 reviews');
xlabel('# of People who gave feedback');
ylabel('# of Users');
subplot(2,1,2);
ind = user_stats(:,1) >= 5 & user_stats(:,1) < 100;
hist(user_stats(ind, 5), bins);
title('Users with >= 5 reviews');
xlabel('# of People who gave feedback');
ylabel('# of Users');
saveas(h, '#feedbacks vs. # users.png');


interesting_users = find(user_stats(:,1) > 40);
for iu = 1:length(interesting_users)
    uid = unique_users(interesting_users(iu));
    IND = m(:,2) == uid;
    jaccard = zeros(length(unique_users),1);
    score_diff = zeros(length(unique_users),1);
    for i = 1:length(unique_users)
         user_id = unique_users(i);
         ind = m(:,2) == user_id;
         jaccard(i) = length(intersect(m(IND, 1), m(ind, 1)))/length(union(m(IND, 1), m(ind, 1)));
         score_diff(i) = abs(user_stats(unique_users == uid, 2) - user_stats(i, 2));
    end

    J = jaccard(jaccard ~= 1);
    h = figure(20); clf;
    plot(J, user_stats(jaccard ~= 1, 2), '*g');
    hold on;
    plot(J, score_diff(jaccard ~= 1), '*m');
    xlabel('Jaccard Ratio');
    ylabel('Score');
    %title('ID-46:User Average Scoer vs. Jaccard Value');
    legend('Average Score', 'Absolute Avg Score Difference');
    saveas(h, sprintf('score-vs-jaccard.%d.png', uid));



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

    saveas(h, sprintf('scores-vs-scorediff.cluster.%d.png', uid));

end

% col#1: # of reviews
% col#2: avg score
% col#3: highest score
% col#4: lowest score
% movie_stats = zeros(length(unique_movies), 4);
% for s=1:length(unique_movies)
%    movie_id = unique_movies(s);
%    m_ind = m(:,1) == movie_id;
%    movie_stats(s,1) = sum(m_ind);
%    movie_stats(s,2) = mean(m(m_ind, 5));
%    movie_stats(s,3) = max(m(m_ind, 5));
%    movie_stats(s,4) = min(m(m_ind, 5));
% end
% 
% figure(8);
% hist(movie_stats(:,1));
% xlabel('# of reviews');
% ylabel('# of movies');
% title('movie_review_count');
% 
% figure(9);
% hist(movie_stats(:,1));
% xlabel('# of reviews');
% ylabel('# of movies');
% title('movie_review_count-logscale');
% set(gca, 'yscale', 'log');
% 
% figure(10);
% hist(movie_stats(:,2));
% xlabel('avg_score');
% ylabel('# of movies');
% title('movie_avg_score');
% 
% figure(11);
% hist(movie_stats(:,3));
% xlabel('highest_score');
% ylabel('# of movies');
% title('movie_highest_score');
