CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) VALUES 
(1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);

CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) VALUES 
(1,'09-22-2017'),
(3,'04-21-2017');

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) VALUES 
(1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

Select * from sales;
Select * from product;
Select * from goldusers_signup;
Select * from users;

--Total Amount each Cx spend on Zomato:

Select sales.userid, sum(product.price) as total_spent
from sales
join product
 on sales.product_id = product.product_id
 group by userid
 order by 1

--How many days each customer visied Zomato

Select sales.userid, count(distinct sales.created_date) as Days_Visited
from sales
group by sales.userid
order by 1

--First product purchased by each Cx

--Using alternate methods

Select * from
(
Select *, rank() over (partition by userid order by created_date) as "Rank"
from sales
) as Ranking
where "Rank" = 1

--2nd method (CTE)

With CTE_Rank as 
(Select *, rank() over (partition by userid order by created_date) as "Rank"
from sales)
Select *
from CTE_Rank
 where "Rank" = 1

--Most purchased item and How many times purchased by all Cx

Select top 1 product_id, count(product_id) as Purchase_Count 
from Sales 
group by product_id 
order by Purchase_Count desc

Select userid, count(product_id) as Purchase_Count from sales where product_id = 
 (Select top 1 product_id from Sales group by product_id order by count(product_id) desc)
group by userid

--Most popular item for each Cx

Select * from 
(Select *, rank() over(partition by userid order by Purchase_Count desc) as "Rank" from 
(Select userid, product_id, count(product_id) as Purchase_Count
from sales
group by userid, product_id) as R) as RR
where "Rank" = 1

--Which item purchased first by the Cx after gold membership 

Select * from 
(Select *, rank() over (partition by userid order by created_date) as "Rank" from
(Select sales.userid, created_date, product_id, gold_signup_date 
from sales
join goldusers_signup
on sales.userid = goldusers_signup.userid
where created_date>gold_signup_date
--order by 1,2
) as A) as B
where "Rank" = 1

--Which item purchased by the Cx just before gold membership 

Select * from 
(Select *, rank() over (partition by userid order by created_date desc) as "Rank" from
(Select sales.userid, created_date, product_id, gold_signup_date 
from sales
join goldusers_signup
on sales.userid = goldusers_signup.userid
where created_date<gold_signup_date
--order by 1,2 desc
) as A) as B
where "Rank" = 1

-- Total order and amount spend by each Cx before gold membership

Select s.userid, count(s.created_date) as Total_Orders, sum(p.price) as Total_Amount 
from sales s
join product p
on s.product_id = p.product_id
join goldusers_signup g
on s.userid = g.userid
where s.created_date<g.gold_signup_date
group by s.userid

--Consider buying each product generates certain points for Cx in the provided manner.
--For each 5Rs spend on p1 = 1 Zomato point
--For each 10Rs spend on p2 = 5 Zomato point
--For each 5Rs spend on p3 = 1 Zomato point

--Calculate points collected by each Cx and for which product most points have been given till now. 

-- Points collected by each Cx:

Select b.userid, sum(b.Points) as Total_Points
from
(Select a.*, 
case
 when a.product_id = 1 then Total_Amount/5
 when a.product_id = 2 then (Total_Amount/10) * 5
 when a.product_id = 3 then Total_Amount/5
end as Points
from 
(Select s.userid, s.product_id, sum(p.price) as Total_Amount
from sales s
join product p
on s.product_id = p.product_id
group by userid, s.product_id) a) b
group by b.userid

-- Product for which most points have been given:

Select d.* from 
(Select c.*, rank() over (order by Total_Points desc) as "Rank"
from
(Select b.product_id, sum(b.points) as Total_Points
from
(Select a.*, 
case
 when a.product_id = 1 then Total_Amount/5
 when a.product_id = 2 then (Total_Amount/10) * 5
 when a.product_id = 3 then Total_Amount/5
end as Points
from 
(Select s.userid, s.product_id, sum(p.price) as Total_Amount
from sales s
join product p
on s.product_id = p.product_id
group by userid, s.product_id) a) b
group by product_id) c) d 
where d.Rank = 1

-- In the first year after Cx joins the gold program, irrespective of what the purchase CX will earn 
-- 5 Zomato points for every 10Rs spent, Need to find total points earned by gold members in first year of program.

Select c.userid, c.Total_Price, (c.Total_Price/10 * 5) as Total_Points from 
(Select b.userid, sum(b.price) as Total_Price from 
(Select a.* from
(Select s.userid, s.created_date, s.product_id, p.price, g.gold_signup_date
from sales s
join goldusers_signup g
on s.userid = g.userid
join product p
on s.product_id = p.product_id) a
where a.created_date >= a.gold_signup_date  and a.created_date <= DATEADD(year, 1, a.gold_signup_date)) b
group by b.userid) c

-- Rank all transactions for each Cx whenever they are gold member, if non gold member mark as 'NA'

Select a.*,		
case 
when a.gold_signup_date is NULL then 'NA'
else cast(rank() over (partition by a.userid order by a.created_date desc) as varchar)
--Note the usage of cast() to accomodate integer and string in same coloumn, we have changed int type of "Rank" column to varchar
end as "Rank" 
from
(Select s.userid, s.created_date, s.product_id, g.gold_signup_date
from sales s 
left join goldusers_signup g
on s.userid = g.userid and s.created_date > g.gold_signup_date) a
