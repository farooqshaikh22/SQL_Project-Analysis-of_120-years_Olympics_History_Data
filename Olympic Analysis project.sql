select * from olympic_history;
select * from noc_region;

-- 1.How many olympics games have been held?
select count(distinct game)total_olympic_games from olympic_history;

-- 2.List down all Olympics games held so far.
select distinct game,city from olympic_history order by game;

-- 3.Mention the total no of nations who participated in each olympics game?

select distinct game,count(distinct region)total_country_participated from olympic_history a
inner join noc_region b
on a.noc = b.noc
group by game

-- 4.Which year saw the highest and lowest no of countries participating in olympics?

with t1 as(
select distinct a.game,b.region from olympic_history a
	
    inner join noc_region b
	on a.noc = b.noc
),
t2 as(
	select game,count(region)total_countries_participated
	from t1
	group by game
)
select distinct concat(
	first_value(game) over(order by game),
	'-',
	first_value(total_countries_participated) over(order by total_countries_participated)
)as lowest_number_of_countries_participated,

concat(first_value(game) over(order by game desc),
	  '-',
	   first_value(total_countries_participated) over(order by total_countries_participated desc)
	  )as highest_number_of_countries_participated
from t2;

-- 5.Which nation has participated in all of the olympic games?

with t1 as(
	select count(distinct game)total_olympic_games from olympic_history	
),
t2 as (
	select distinct a.game,b.region from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	group by a.game,b.region
),
t3 as (
	select region,count(region)participated_year_count
	from t2
	group by region
)
select * from t3 where participated_year_count = 
(select total_olympic_games from t1);


-- 6.Identify the sport which was played in all summer olympics.

with t1 as(
	select count(distinct game)total_summer_game from olympic_history
	where season = 'Summer'
),
t2 as ( 
	select distinct game,sport from olympic_history
	where season = 'Summer'	
),
t3 as (
	select sport,count(sport)sport_count from t2
	group by sport
)
select * from t3 where sport_count = 
(select total_summer_game from t1);


-- 7.Which Sports were just played only once in the olympics.

with t1 as(
	select distinct game,sport from olympic_history
),
t2 as (
	select sport,count(1)sport_count from t1
	group by sport
)
select t2.*,t1.game from t2
inner join t1
on t2.sport = t1.sport
where sport_count=1
order by sport;


-- 8.Fetch the total no of sports played in each olympic games.

select distinct game,count(distinct sport)total_sport from olympic_history
group by game order by total_sport desc


-- 9.Fetch oldest athletes to win a gold medal

with t1 as(
	select distinct(name),medal,age from olympic_history
    where age <> 'NA' and medal = 'Gold'
),
t2 as(
	select*,
	rank() over(order by age desc)rnk
	from t1
)
select name,medal,age from t2 where rnk=1;


-- 10. Find the Ratio of male and female athletes participated in all olympic games.
with t1 as (
	select distinct sex,count(sex)total_count from olympic_history
    group by sex
),
t2 as (
	select *,
	rank() over(order by total_count)rnk
	from t1
),
t3 as (
	select total_count as min_count from t2
	where rnk=1
),
t4 as (
	select total_count as max_count from t2
	where rnk=2
)
select concat('1:',round(t4.max_count*1.0/t3.min_count,2))ratio
from t3,t4

-- 11. Fetch the top 5 athletes who have won the most gold medals.

with t1 as (
	select name,count(1)total_medal from olympic_history
	where medal = 'Gold'
	group by name
),
t2 as (
	select *,
	dense_rank() over(order by total_medal desc)rnk
	from t1			
)
select name,total_medal from t2 where rnk <= 5;

-- 12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as (
	select name,count(medal)total_medal from olympic_history
	where medal <> 'NA'
	group by name
),
t2 as (
	select *,
	dense_rank() over (order by total_medal desc)rnk
	from t1
)
select name,total_medal from t2 where rnk <= 5;

-- 13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as (
	select b.region,count(a.medal)total_medal from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	where a.medal <> 'NA'
	group by region
),
t2 as (
	select *,
	dense_rank() over(order by total_medal desc)rnk
	from t1
)
select * from t2 where rnk <= 5;


-- 14.List down total gold, silver and bronze medals won by each country.

with t1 as (
	select b.region,a.medal,count(2)cnt from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	where medal <> 'NA'
	group by b.region,a.medal
),
t2 as (
	select region,
	sum(case when medal = 'Gold' then cnt end) as gold_medal,
	sum(case when medal = 'Silver' then cnt end) as silver_medal,
	sum(case when medal = 'Bronze' then cnt end) as bronze_medal
	from t1
	group by region
),
t3 as (
	select region,
	coalesce(gold_medal,0)gold,
	coalesce(silver_medal,0)silver,
	coalesce(bronze_medal,0)bronze
	from t2
)
select * from t3 
order by gold desc,silver desc,bronze desc


-- 15.List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
with t1 as (
	select a.game,b.region ,a.medal,count(medal)cnt from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	where a.medal <> 'NA'
	group by a.game,b.region ,a.medal
),
t2 as (
	select game,region,
	sum(case when medal ='Gold' then cnt end )as gold_medal,
	sum(case when medal ='Silver' then cnt end )as silver_medal,
	sum(case when medal ='Bronze' then cnt end )as bronze_medal
	from t1
	group by game,region
),
t3 as (
	select game,region,
	coalesce(gold_medal,0)gold,
	coalesce(silver_medal,0)silver,
	coalesce(bronze_medal,0)bronze
	from t2
)
select * from t3
order by game,region;

-- 16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.

with t1 as (
	select a.game,b.region,a.medal,count(a.medal)cnt from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	where medal <> 'NA'
	group by a.game,b.region,a.medal
),
t2 as (
	select game,region,
	coalesce(sum(case when medal = 'Gold' then cnt end),0) as gold_medal,
	coalesce(sum(case when medal = 'Silver' then cnt end),0) as silver_medal,
	coalesce(sum(case when medal = 'Bronze' then cnt end),0) as bronze_medal
	from t1
	group by game,region
),
t3 as (
	select *,
	rank() over(partition by game order by gold_medal desc)gold_rank,
	rank() over(partition by game order by silver_medal desc)silver_rank,
	rank() over(partition by game order by bronze_medal desc)bronze_rank
	from t2	
),
t4 as (
	select game,
	max(case when gold_rank=1 then concat(region,'-',gold_medal) end) as highest_gold_medal,
	max(case when silver_rank=1 then concat(region,'-',silver_medal) end) as highest_silver_medal,
	max(case when bronze_rank=1 then concat(region,'-',bronze_medal) end) as highest_bronze_medal
	from t3
	group by game
	
)
select * from t4
order by game

-- 17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with t1 as (
	select a.game,b.region,a.medal,count(a.medal)cnt from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	where medal <> 'NA'
	group by a.game,b.region,a.medal
),
t2 as (
	select game,region,
	coalesce(sum(case when medal = 'Gold' then cnt end),0) as gold_medal,
	coalesce(sum(case when medal = 'Silver' then cnt end),0) as silver_medal,
	coalesce(sum(case when medal = 'Bronze' then cnt end),0) as bronze_medal
	from t1
	group by game,region
),
t3 as (
	select *,gold_medal + silver_medal + bronze_medal as total_medal
	from t2
),
t4 as (
	select game,region,gold_medal,silver_medal,bronze_medal,total_medal,
	rank() over(partition by game order by gold_medal desc)gold_rank,
	rank() over(partition by game order by silver_medal desc)silver_rank,
	rank() over(partition by game order by bronze_medal desc)bronze_rank,
	rank() over(partition by game order by total_medal desc )total_rank
	from t3
),
t5 as (
	select game,
	max(case when gold_rank=1 then concat(region,'-',gold_medal) end) as highest_gold_medal,
	max(case when silver_rank=1 then concat(region,'-',silver_medal) end) as highest_silver_medal,
	max(case when bronze_rank=1 then concat(region,'-',bronze_medal) end) as highest_bronze_medal,
	max(case when total_rank=1 then concat(region,'-',total_medal) end) as highest_total_medal
	from t4
	group by game
)
select * from t5

-- 18.Which countries have never won gold medal but have won silver/bronze medals?

with t1 as (
	select b.region,a.medal,count(3)cnt from olympic_history a
	inner join noc_region b
	on a.noc = b.noc
	where medal <> 'NA'
	group by b.region,a.medal
),
t2 as (
	select region,
	coalesce(sum(case when medal='Gold' then cnt end),0) as gold_medal,
	coalesce(sum(case when medal='Silver' then cnt end),0) as silver_medal,
	coalesce(sum(case when medal='Bronze' then cnt end),0) as bronze_medal
	from t1
	group by region
)
select * from t2 where gold_medal=0 and (silver_medal > 0 or bronze_medal > 0)

-- 19.In which Sport/event, India has won highest medals.

with t1 as(
	select b.region country,a.sport,a.medal from olympic_history a
	inner join noc_region b
	on a.noc=b.noc
	where b.region = 'India' and medal <> 'NA'	
),
t2 as (
	select country,sport,count(sport)total_medal,
	rank() over(order by count(sport) desc)rnk
	from t1
	group by country,sport
)
select country,sport,total_medal from t2 where rnk=1;

-- 20.Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

with t1 as (
	select a.game,b.region,a.sport,a.medal from olympic_history a
	inner join noc_region b
	on a.noc=b.noc
	where region = 'India' and sport = 'Hockey' and medal <> 'NA'
),
t2 as (
	select game,count(medal)total_hockey_medals
	from t1
	group by game
)
select distinct t1.region,t1.sport,t2.* from t2
inner join t1
on t1.game =t2.game



  