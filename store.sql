--drop column which will not use in eda.
alter table superstore
drop column customer_id,
drop column postal_code,
drop column order_id;


1).in which country has superstore services?

select distinct(country) from superstore
---> this store is only in US

2). Which customer made highest order in terms of sales vs profit?(top 10)

select customer_name, round(sum(sales) :: decimal,2) as sales, round(sum(profit) :: decimal,2) as profit from superstore
group by customer_name
order by profit desc
limit 10

3).Shipping mode types in terms of sales and no_of_count?
 select ship_mode, count(*) as no_of_shipment_made, 
 round(sum(sales) :: decimal,2) as sales,
 round(sum(profit) :: decimal,2) as profit 
 from superstore
 group by ship_mode
 order by no_of_shipment_made desc
----> Standard class shipping is cheaper than any other shipping method. 
----> unable to see connection between shipmode,profit and sales due to unavailability of shipping price.

4). which segment prefer which type of ship_mode?
with t1 as
		(select segment, ship_mode,
		count(*) as shipping_mode_preference from superstore
		group by segment, ship_mode
		order by segment)
	
	select segment, ship_mode, count_shipmode
	from
		(select *,
		dense_rank() over(partition by ship_mode order by shipping_mode_preference desc) as rnk,
		max(shipping_mode_preference)
		over(partition by ship_mode order by shipping_mode_preference desc) as count_shipmode from t1) as x
		where x.rnk = 1 
------>  largest no. of purchse made by consumer.
------>  they are first in every types of ship_mode.
		
5). Which product category are in demand? Why?
select category, count(*) as count_of_product from superstore
group by category
order by count_of_product desc
-----> Office Supplies category are in demands.

----Now try  to find what are products come under office supplies
select sub_category, count(*) as products_count from superstore
where category = 'Office Supplies'
group by sub_category
order by products_count desc

------want to know: are consumer the one  who buys more office supplies products since they purchased in largest no.
select segment, category, count(*) as cnt from superstore
where category ='Office Supplies'
group by segment,category
order by cnt desc
limit 1
----> Yes, consumer spent more amt in office supplies.

-----> further digging: lets take a look into product_name of office supplies category
select product_name from superstore
where category ='Office Supplies'
----> these product are mainly used in corporate.
----->Weird because consumer purchses more such type of product. in this data, may be consumer are also related to corporate field.(Can't say)


6). Which category, sub_Category made max sales?
with t1 as
	(select category,sub_category,sum(sales):: integer as sales from superstore
	 group by category,sub_category
	order by  sales desc)
	
	select category,sub_category, max_sales_category, max_sales_sub_category 
	from
	(select *,
	dense_rank() over(partition by category order by sales desc) as rnk,
	max(sales) over(partition by category order by sales desc) as max_sales_category,
	max(sales) over(partition by sub_category order by sales desc) as max_sales_sub_category
	from t1) as x
	where x.rnk =1
-----> in category furniture sale is high, in this chair is in more demand
-----> office supplies - storage(sub_category) is in demand
-----> technology - phones (no doubt!)	

7). In which category and sub_category , store had to bear loss.
select category,sub_category, sum(sales)::integer as sales, sum(discount):: integer as total_discount_per_subcategory,
sum(profit)::integer as loss 
from superstore
 where profit <0
group by category,sub_category
order by loss asc
--->from this we can say higher the discount, higher the loss.on the other hand, binders gave so much profit to store.Depends on store policy.
--->  Why store gave so much discount mostly on binders.
	
8). From which state,city most order placed.
with t1 as
		(select state, city, count(*)  as order_placed from superstore
		group by state, city)
		
		select state,city, max_order_placed_category, max_order_placed_sub_category 
			from	
			(select *,
			dense_rank() over(partition by state order by order_placed desc) as rnk,
			max(order_placed) over(partition by state order by order_placed desc) as max_order_placed_category,
			max(order_placed) over(partition by city order by order_placed desc) as max_order_placed_sub_category
			from t1) as x
			where x.rnk = 1
			order by max_order_placed_category desc, max_order_placed_sub_category asc
			
----> Most order placed by NYC followed by LA, Philadelphia.
		
9). Which state, city is more profitable for store?		
		
with t1 as
		(select state, city, sum(profit)::integer  as total_profit from superstore
		group by state, city)
		
		select state,city, max_order_total_profit_category, max_order_total_profit_sub_category 
			from	
			(select *,
			dense_rank() over(partition by state order by total_profit desc) as rnk,
			max(total_profit) over(partition by state order by total_profit desc) as max_order_total_profit_category,
			max(total_profit) over(partition by city order by total_profit desc) as max_order_total_profit_sub_category
			from t1) as x
			where x.rnk = 1
			order by max_order_total_profit_category desc, max_order_total_profit_sub_category asc		
	
-----> 1.NYC   2.LA    3.Seattle
--> from this we can say, order_placed is not directly proportional to profit.

10). Which region is more profitable for store?
select region, sum(profit) :: integer as total_profit from superstore
group by region order by total_profit desc

--Year extract
alter table superstore
add column year text;
update superstore
set year= right(order_date,4) 

11). Yearwise sales and profit.
select year,sum(sales):: integer as total_sales,
sum(profit) :: integer as total_profit 
from superstore
group by year
order by year

--replace '/' to '-' in date col.
update superstore
set order_date= replace(order_date,'/','-')
update superstore
set ship_date= replace(order_date,'/','-')
--
update superstore
set ship_date= to_date(ship_date,'mm-dd-yyyy')

12). In which date highest 'same day' shipment booked by month?
with t1 as
		(select s1.order_date,s2.ship_date,count(*) as countof_same_day_ship from superstore as s1
		left join superstore s2
		on s1.order_date= s2.ship_date
		group by s1.order_date, s2.ship_date)
		
		select order_date, ship_date, countof_same_day_ship
		from (select *,dense_rank()
			over(partition by substring(order_date, 1, 7)
				 order by countof_same_day_ship desc ) as same_day_ship from t1) as x
			where x.same_day_ship=1
-----> in all  the year, same day shipment booked mostly in sep. ,nov., dec. month.
----> May be because of discount/ sales season.
---->This is the pattern which i find.			
	



