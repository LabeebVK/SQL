select * from customer_orders;

select * from driver_order;

select * from ingredients;

select * from driver;

select * from rolls;

select * from rolls_recipes;

--1. How many rolls were ordered?

Select COUNT(order_id) as Total_rolls_ordered from customer_orders

--2. How many unique Cx orders were made?

Select count(Distinct customer_id) as Unique_Customers from customer_orders

--3. How many successful orders were delivered by each driver?

Select a.driver_id, count(a.cancel_status) Delivered from 
(Select *,
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then 'C'
 else 'NC'
 end as cancel_status
from driver_order) a
where a.cancel_status != 'C'
group by a.driver_id

--4. How many each type of roll delivered?

Select roll_id, count(roll_id) Delivered from
(Select c.roll_id,  
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then 'C'
 else 'NC'
 end as cancel_status from
(Select b.order_id, b.roll_id, a.cancellation
from driver_order a
join customer_orders b
on a.order_id = b.order_id) c) d
where cancel_status != 'C'
group by roll_id

--5. How many veg and non veg rolls were ordered by each Cx?

Select a.customer_id, r.roll_name, a.Total_Order from
(Select customer_id, roll_id, count(roll_id) as Total_Order 
from customer_orders
group by customer_id, roll_id) a 
join rolls r
on a.roll_id = r.roll_id
order by 1

--6. Maximum no.of rolls delivered in a single order?

Select TOP 1 c.order_id, count(roll_id) as Total_rolls_delivered from
(Select a.order_id, a.roll_id, b.cancellation, 
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then 'C'
 else 'NC'
 end as cancel_status
from customer_orders a
join driver_order b
on a.order_id = b.order_id) c
where c.cancel_status = 'NC'
group by c.order_id
order by 2 desc

--7. For each Cx how many ordered rolls had atleast 1 change and had no change?

Select b.customer_id, b.Changes,
case when b.Changes = 'YES' then count(Changes)
else 0
end as No_of_changes
from
(Select a.*, 
case
 when a.new_not_included = '0' and a.new_extra_included = '0' then 'NO'
 else 'YES'
end as Changes
from
(Select customer_id,
case 
 when not_include_items is NULL or not_include_items = ' ' then '0'
  else not_include_items
  end as new_not_included,
case 
 when extra_items_included is NULL or extra_items_included = 'NaN' or extra_items_included = ' ' then '0'
 else extra_items_included
 end as new_extra_included
from customer_orders) a) b
group by b.customer_id, b.Changes
order by 2 desc

--8. How many rolls were delivered that had both exclusions and extras?

Select count(c.both_exclusion_and_extras) as Delivered_with_exclusion_and_extra from
(Select a.order_id, a.not_include_items, a.extra_items_included, b.cancellation, 
case
 when a.not_include_items = ' ' or a.not_include_items is NULL or a.extra_items_included in (' ', 'NaN') or a.extra_items_included is NULL then 'NO'
 else 'YES'
end both_exclusion_and_extras,
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then 'C'
 else 'NC'
end as cancel_status
from customer_orders a
join driver_order b
on a.order_id = b.order_id) c
where c.both_exclusion_and_extras = 'YES' and c.cancel_status = 'NC'

--9. Total no.of rolls ordered in each hour of the day.

Select a.Hour_Range, count(a.order_id) Total_Orders from
(Select *, CONCAT(DATEPART(hour, order_date),' - ', DATEPART(HOUR, order_date) + 1) as Hour_Range from customer_orders) a
group by a.Hour_Range

--10. Total no.of orders in each day of the week

Select a.Day, count(DISTINCT a.order_id) Total_Orders from
(Select *, DATENAME(DW, order_date) as Day from customer_orders) a
group by a.Day



--11. Average time in minutes required for each driver to reach Fasoos HQ to pickup order.

Select r.driver_id, AVG(r.Diff) as Pickup_time_required from 
(Select c.*, DATEDIFF(minute, c.order_date, c.pickup_time) as Diff from
(Select distinct a.order_id, b.driver_id, a.order_date, b.pickup_time
from customer_orders a
join driver_order b
on a.order_id = b.order_id
where b.pickup_time is not null) c) r
group by r.driver_id

--12. Relation between No.off rolls ordered and time required to prepare.

With CTE_Relation as
(Select c.order_id, count(c.roll_id) as total_rolls_ordered, c.prepare_time from 
(Select a.order_id, a.roll_id, DATEDIFF(minute, a.order_date, b.pickup_time) as Prepare_time
from customer_orders a
join driver_order b
on a.order_id = b.order_id 
where b.pickup_time is not null) c
group by c.order_id, c.Prepare_time)
Select total_rolls_ordered, prepare_time from CTE_Relation
order by 1
--We can conclude, on an average 10 minutes required to prepare for 1 roll ordered.

--13. Average distance travelled for each Cx

Select d.customer_id, avg(d.distance) avg_distance from
(Select distinct c.order_id, c.customer_id, c.distance from
(Select a.order_id, customer_id, CAST(TRIM(REPLACE(lower(a.distance), 'km', ' ')) as float) as distance,   
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then 'C'
 else 'NC'
 end as cancel_status
from driver_order a
join customer_orders b
on a.order_id = b.order_id) c
where cancel_status != 'C' or distance is not null) d
group by d.customer_id

--14. Clean the duration column data and find difference between longest and shortest delivery time of all orders

Select MAX(a.duration1) - MIN(a.duration1) difference from 
(Select duration, cast(substring(duration, 1, 2) as int) as duration1 from driver_order) a

--15. Average speed of each driver

Select b.driver_id, round(AVG(b.distance/(b.duration/60)), 1) avg_speed_kmhr from
(Select a.driver_id, cast(SUBSTRING(a.distance, 1, 2) as float) distance, cast(SUBSTRING(a.duration, 1, 2) as float) duration from
(Select driver_id, distance, duration, 
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then 'C'
 else 'NC'
end as cancel_status
from driver_order) a
where a.cancel_status != 'C') b
group by b.driver_id

--16. Successful delivery percentage for each driver

Select c.driver_id, (c.delivered/c.orders_taken)*100 as successful_delivery_percent from
(Select b.driver_id, sum(b.cancel_status) as delivered, count(b.driver_id) as orders_taken from
(Select a.driver_id, cast(cancel_status as float) cancel_status from 
(Select driver_id, 
case
 when cancellation in ('Cancellation', 'Customer Cancellation') then '0'
 else '1'
end as cancel_status
from driver_order) a) b
group by b.driver_id) c