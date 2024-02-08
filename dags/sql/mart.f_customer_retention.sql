INSERT INTO  mart.f_customer_retention (item_id, new_customers_count, returning_customers_count, refunded_customer_count, period_id, new_customers_revenue, returning_customers_revenue, customers_refunded)
WITH new_customers as
         (select item_id,
         		 count(distinct customer_id) as new_customers_count, 
         		 sum(payment_amount) as new_customers_revenue,
         		 week_of_year 
          from mart.f_sales
          join mart.d_calendar on f_sales.date_id = d_calendar.date_id
          group by item_id, week_of_year),	      
     returning_customers as
         (select a.item_id,
	   			 count(distinct a.returning_count) as returning_customers_count, 
       			 sum(a.returning_sum) as returning_customers_revenue,
       			 a.week_of_year as week_of_year
						from (select item_id,
	   								 customer_id,
							         count(item_id) over (partition by (item_id, week_of_year, customer_id)) as returning_count,
							         sum(payment_amount) over (partition by (item_id, week_of_year, customer_id)) as returning_sum,
								     week_of_year	 
							  from mart.f_sales 
							  join mart.d_calendar on f_sales.date_id = d_calendar.date_id
							  group by item_id, customer_id, week_of_year, payment_amount) as a
							  where a.returning_count > 1
							  group by item_id, week_of_year),          
     refunded_customers as
         (select item_id,
         		 count(distinct customer_id) as refunded_customer_count, 
         		 count(quantity) as customers_refunded,
         		 week_of_year 
          from mart.f_sales
          join mart.d_calendar on f_sales.date_id = d_calendar.date_id
          where status = 'refunded'
          group by item_id, week_of_year)      
SELECT 
  new_customers.item_id,
  new_customers.new_customers_count,
  returning_customers.returning_customers_count,
  refunded_customers.refunded_customer_count,
  new_customers.week_of_year as period_id,
  new_customers.new_customers_revenue,
  returning_customers.returning_customers_revenue,
  refunded_customers.customers_refunded
FROM new_customers
LEFT JOIN returning_customers ON new_customers.item_id=returning_customers.item_id AND new_customers.week_of_year=returning_customers.week_of_year
LEFT JOIN refunded_customers ON new_customers.item_id=refunded_customers.item_id AND new_customers.week_of_year=refunded_customers.week_of_year;  